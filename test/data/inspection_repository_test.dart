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

  test('startInspection saves a draft for the scanned asset', () async {
    final id = await repo.startInspection('PUMP-42');

    final saved = await db.select(db.inspections).getSingle();
    expect(saved.id, id);
    expect(saved.assetCode, 'PUMP-42');
    expect(saved.status, 'draft');
  });

  test('watchInspections shows new inspections', () async {
    await repo.startInspection('PUMP-1');
    await repo.startInspection('PUMP-2');

    final list = await repo.watchInspections().first;
    expect(list.map((i) => i.assetCode), containsAll(['PUMP-1', 'PUMP-2']));
  });
}
