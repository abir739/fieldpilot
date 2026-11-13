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

  test('watchInspections shows new inspections', () async {
    await repo.openOrStartDraft('PUMP-1');
    await repo.openOrStartDraft('PUMP-2');

    final list = await repo.watchInspections().first;
    expect(list.map((i) => i.assetCode), containsAll(['PUMP-1', 'PUMP-2']));
  });
}
