import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpilot/data/inspection_repository.dart';
import 'package:fieldpilot/data/local/app_database.dart';
import 'package:fieldpilot/sync/pull_engine.dart';
import 'package:fieldpilot/sync/push_engine.dart';
import 'package:fieldpilot/sync/sync_scheduler.dart';

import 'fake_pull_server.dart';
import 'fake_push_server.dart';

void main() {
  late AppDatabase db;
  late FakePullServer server;
  late PullEngine engine;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    server = FakePullServer();
    engine = PullEngine(db, server);
  });
  tearDown(() => db.close());

  const id = '11111111-1111-1111-1111-111111111111';
  Map<String, dynamic> inspection({String note = '', int version = 1}) => {
        'id': id,
        'asset_code': 'PUMP-42',
        'status': 'draft',
        'note': note,
        'version': version,
        'updated_at': '2026-01-01T10:00:00.000Z',
      };
  Future<Inspection> local() =>
      (db.select(db.inspections)..where((i) => i.id.equals(id))).getSingle();

  test('empty phone gets all its server rows back (e.g. after reinstall)', () async {
    server.write('inspections', inspection(note: 'from server'));
    server.write('answers', {
      'id': '$id|No leaks',
      'inspection_id': id,
      'question': 'No leaks',
      'ok': true,
    });

    await engine.pullAll();

    expect((await local()).note, 'from server');
    expect((await db.select(db.answers).getSingle()).ok, isTrue);
  });

  test('next pull asks only for newer rows (a little overlap is safe)', () async {
    server.write('inspections', inspection());
    await engine.pullAll();
    final cursor = (await db.select(db.syncCursors).get())
        .singleWhere((c) => c.name == 'inspections')
        .seenUntil;

    server.write('inspections', inspection(note: 'edited on the web', version: 2));
    await engine.pullAll();

    expect(server.asked['inspections']!.last, cursor.subtract(PullEngine.overlap));
    expect((await local()).note, 'edited on the web');
    expect((await local()).version, 2);
  });

  test('a row with an unsent local edit is not overwritten by pull', () async {
    server.write('inspections', inspection(note: 'v1'));
    await engine.pullAll();
    await InspectionRepository(db).setNote(id, 'my offline edit'); // in the outbox

    server.write('inspections', inspection(note: 'web edit', version: 2));
    await engine.pullAll();

    expect((await local()).note, 'my offline edit'); // push will decide
  });

  test('offline: nothing saved, bookmark not moved', () async {
    server.write('inspections', inspection());
    server.offline = true;

    await expectLater(engine.pullAll(), throwsException);

    expect(await db.select(db.inspections).get(), isEmpty);
    expect(await db.select(db.syncCursors).get(), isEmpty);
  });

  test('a full sync pushes first, then pulls; a failed pull is reported', () async {
    final push = PushEngine(db, FakePushServer());
    await InspectionRepository(db).openOrStartDraft('PUMP-42');
    server.offline = true;

    final result = await pushThenPull(push, engine);

    expect(result.sent, 1); // the push still happened
    expect(result.failed, isTrue); // but the pull did not: retry later
  });
}
