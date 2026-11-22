import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpilot/data/inspection_repository.dart';
import 'package:fieldpilot/data/local/app_database.dart';

void main() {
  late AppDatabase db;
  late InspectionRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = InspectionRepository(db);
  });
  tearDown(() => db.close());

  test('closing the conflict banner clears it and sends nothing', () async {
    final draft = await repo.openOrStartDraft('PUMP-42');
    await db.delete(db.outbox).go(); // pretend it was synced
    await (db.update(db.inspections)..where((i) => i.id.equals(draft.id)))
        .write(InspectionsCompanion(serverWonAt: Value(DateTime.now())));

    await repo.dismissServerWon(draft.id);

    expect((await repo.watchInspection(draft.id).first).serverWonAt, isNull);
    expect(await db.select(db.outbox).get(), isEmpty); // phone-only flag
  });

  test('creates a draft for a new asset', () async {
    final created = await repo.openOrStartDraft('PUMP-42');

    final saved = await db.select(db.inspections).getSingle();
    expect(saved.id, created.id);
    expect(saved.assetCode, 'PUMP-42');
    expect(saved.status, 'draft');
  });

  test('scanning the same asset again reuses its draft', () async {
    final first = await repo.openOrStartDraft('TANK_001');
    final second = await repo.openOrStartDraft('TANK_001');

    expect(second.id, first.id);
    expect(await db.select(db.inspections).get(), hasLength(1));
  });

  test('setNote saves the note', () async {
    final draft = await repo.openOrStartDraft('PUMP-42');

    await repo.setNote(draft.id, 'small oil leak');

    final saved = await db.select(db.inspections).getSingle();
    expect(saved.note, 'small oil leak');
  });

  test('watchInspections shows new inspections', () async {
    await repo.openOrStartDraft('PUMP-1');
    await repo.openOrStartDraft('PUMP-2');

    final list = await repo.watchInspections().first;
    expect(list.map((i) => i.assetCode), containsAll(['PUMP-1', 'PUMP-2']));
  });
}
