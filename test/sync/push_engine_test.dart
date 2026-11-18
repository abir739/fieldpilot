import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpilot/data/answer_repository.dart';
import 'package:fieldpilot/data/inspection_repository.dart';
import 'package:fieldpilot/data/local/app_database.dart';
import 'package:fieldpilot/sync/push_api.dart';
import 'package:fieldpilot/sync/push_engine.dart';

import 'fake_push_server.dart';

void main() {
  late AppDatabase db;
  late InspectionRepository inspections;
  late AnswerRepository answers;
  late FakePushServer server;
  late PushEngine engine;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    inspections = InspectionRepository(db);
    answers = AnswerRepository(db);
    server = FakePushServer();
    engine = PushEngine(db, server);
  });
  tearDown(() => db.close());

  Future<List<OutboxData>> outbox() => db.select(db.outbox).get();
  Future<Inspection> local(String id) =>
      (db.select(db.inspections)..where((i) => i.id.equals(id))).getSingle();

  test('sends everything in order, empties the outbox, saves the new version', () async {
    final draft = await inspections.openOrStartDraft('PUMP-42');
    await answers.setAnswer(draft.id, 'No leaks', true);

    final result = await engine.pushAll();

    expect(server.calls, ['inspection', 'answer']);
    expect(result.sent, 2);
    expect(await outbox(), isEmpty);
    expect((await local(draft.id)).version, 1);
    expect(server.answers, hasLength(1));
  });

  test('a later edit is based on the new version (no false conflict)', () async {
    final draft = await inspections.openOrStartDraft('PUMP-42');
    await engine.pushAll();

    await inspections.setNote(draft.id, 'oil leak');
    final result = await engine.pushAll();

    expect(result.conflicts, 0);
    expect(server.inspections[draft.id]!['note'], 'oil leak');
    expect((await local(draft.id)).version, 2);
  });

  // Required sync test: retry after network error.
  test('network error: entry kept with 1 attempt, sent on the next run', () async {
    await inspections.openOrStartDraft('PUMP-42');
    server.failBeforeServer = true;

    final first = await engine.pushAll();
    expect(first.failed, isTrue);
    expect((await outbox()).single.attempts, 1);

    final second = await engine.pushAll();
    expect(second.failed, isFalse);
    expect(await outbox(), isEmpty);
  });

  // Required sync tests: app killed before server ack + duplicate push.
  test('answer lost after the server applied it: entry kept, resend is not applied twice', () async {
    final draft = await inspections.openOrStartDraft('PUMP-42');
    server.failAfterServer = true;

    await engine.pushAll();
    expect(await outbox(), hasLength(1)); // kept: we never got the answer
    expect((await local(draft.id)).version, 0);

    await engine.pushAll(); // same op id again
    expect(await outbox(), isEmpty);
    expect(server.inspections[draft.id]!['version'], 1); // applied once only
    expect((await local(draft.id)).version, 1); // replayed answer gave us v1
  });

  // Required sync test: conflict, server wins.
  test('conflict: server copy replaces ours and our unsent edit is dropped', () async {
    final draft = await inspections.openOrStartDraft('PUMP-42');
    await engine.pushAll();
    // Someone else changes it on the server (now v2).
    server.inspections[draft.id] = {
      ...server.inspections[draft.id]!,
      'note': 'changed on server',
      'version': 2,
    };

    await inspections.setNote(draft.id, 'my offline edit'); // based on v1
    final result = await engine.pushAll();

    expect(result.conflicts, 1);
    final mine = await local(draft.id);
    expect(mine.note, 'changed on server');
    expect(mine.version, 2);
    expect(await outbox(), isEmpty);
  });

  test('a refused entry is removed and does not block the ones after it', () async {
    final draft = await inspections.openOrStartDraft('PUMP-42');
    await answers.setAnswer(draft.id, 'No leaks', true);
    server.rejectNext = true; // the inspection is refused

    final result = await engine.pushAll();

    expect(result.rejected, 1);
    expect(result.failed, isFalse);
    expect(server.calls, ['inspection', 'answer']); // kept going
    expect(await outbox(), isEmpty);
  });

  test('a network error is not treated as refused', () {
    expect(isPermanentError('23503'), isTrue); // missing parent row
    expect(isPermanentError('42501'), isTrue); // not allowed
    expect(isPermanentError('P0001'), isTrue); // raised by push_op
    expect(isPermanentError('PGRST301'), isFalse); // login expired: retry
    expect(isPermanentError(null), isFalse);
  });

  test('an edit made while sending is kept and sent next time', () async {
    final draft = await inspections.openOrStartDraft('PUMP-42');
    server.whileSending = () async {
      server.whileSending = null;
      await inspections.setNote(draft.id, 'typed during sync');
    };

    await engine.pushAll();
    expect(await outbox(), hasLength(1)); // the newer edit is still waiting

    await engine.pushAll();
    expect(server.inspections[draft.id]!['note'], 'typed during sync');
    expect(await outbox(), isEmpty);
  });
}
