import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpilot/data/answer_repository.dart';
import 'package:fieldpilot/data/inspection_repository.dart';
import 'package:fieldpilot/data/local/app_database.dart';
import 'package:fieldpilot/sync/outbox_writer.dart';

void main() {
  late AppDatabase db;
  late InspectionRepository inspections;
  late AnswerRepository answers;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    inspections = InspectionRepository(db);
    answers = AnswerRepository(db);
  });
  tearDown(() => db.close());

  Future<List<OutboxData>> outbox() => db.select(db.outbox).get();

  test('a new inspection adds one outbox entry with its data', () async {
    final draft = await inspections.openOrStartDraft('PUMP-42');

    final ops = await outbox();
    expect(ops, hasLength(1));
    expect(ops.single.entity, 'inspection');
    expect(ops.single.entityId, draft.id);
    final payload = jsonDecode(ops.single.payload) as Map<String, dynamic>;
    expect(payload['asset_code'], 'PUMP-42');
    expect(payload['status'], 'draft');
  });

  test('reopening an existing draft adds nothing', () async {
    await inspections.openOrStartDraft('PUMP-42');
    await inspections.openOrStartDraft('PUMP-42');

    expect(await outbox(), hasLength(1));
  });

  test('many note changes keep only the newest unsent entry, with a new op id', () async {
    final draft = await inspections.openOrStartDraft('PUMP-42');
    final firstOpId = (await outbox()).single.opId;

    await inspections.setNote(draft.id, 'oil');
    await inspections.setNote(draft.id, 'oil leak');

    final ops = await outbox();
    expect(ops, hasLength(1));
    expect(ops.single.opId, isNot(firstOpId));
    expect(jsonDecode(ops.single.payload)['note'], 'oil leak');
  });

  test('each answer gets its own entry; re-answering replaces it', () async {
    final draft = await inspections.openOrStartDraft('PUMP-42');

    await answers.setAnswer(draft.id, 'No leaks', true);
    await answers.setAnswer(draft.id, 'Labels readable', true);
    await answers.setAnswer(draft.id, 'No leaks', false);

    final answerOps = (await outbox()).where((o) => o.entity == 'answer').toList();
    expect(answerOps, hasLength(2));
    final noLeaks = answerOps.singleWhere((o) => o.entityId == '${draft.id}|No leaks');
    expect(jsonDecode(noLeaks.payload)['ok'], false);
  });

  test('a replaced entry keeps its place: inspection still goes before its answers', () async {
    final draft = await inspections.openOrStartDraft('PUMP-42');
    await answers.setAnswer(draft.id, 'No leaks', true);
    await inspections.setNote(draft.id, 'edited after the answer');

    final inLine = await outboxInOrder(db);
    expect(inLine.map((o) => o.entity), ['inspection', 'answer']);
  });

  test('if the data change fails, no outbox entry is left behind', () async {
    // Answer for an inspection id that does not exist: setNote finds no row,
    // so the transaction throws and must roll back.
    await expectLater(inspections.setNote('missing-id', 'x'), throwsA(anything));

    expect(await outbox(), isEmpty);
  });
}
