import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpilot/data/local/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('saves and reads back an inspection', () async {
    await db.into(db.inspections).insert(InspectionsCompanion.insert(
          id: 'i1',
          assetCode: 'PUMP-42',
          status: 'draft',
          updatedAt: DateTime(2026, 1, 1),
        ));

    final saved = await db.select(db.inspections).getSingle();

    expect(saved.assetCode, 'PUMP-42');
    expect(saved.version, 0); // default value
  });

  test('outbox starts with 0 attempts', () async {
    await db.into(db.outbox).insert(OutboxCompanion.insert(
          opId: 'op1',
          entity: 'inspection',
          payload: '{}',
          createdAt: DateTime(2026, 1, 1),
        ));

    final op = await db.select(db.outbox).getSingle();

    expect(op.attempts, 0);
  });
}
