import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpilot/data/local/app_database.dart';

void main() {
  test('upgrading from schema 1 keeps data and adds the new columns', () async {
    // Build a database exactly like the one on a phone that still runs schema 1.
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('''
        CREATE TABLE inspections (
          id TEXT NOT NULL PRIMARY KEY,
          asset_code TEXT NOT NULL,
          status TEXT NOT NULL,
          version INTEGER NOT NULL DEFAULT 0,
          updated_at INTEGER NOT NULL
        )''');
      raw.execute('''
        CREATE TABLE outbox (
          op_id TEXT NOT NULL PRIMARY KEY,
          entity TEXT NOT NULL,
          payload TEXT NOT NULL,
          attempts INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        )''');
      raw.execute("INSERT INTO inspections VALUES ('i1', 'PUMP-42', 'draft', 0, 0)");
      raw.execute("INSERT INTO outbox VALUES ('op1', 'inspection', '{}', 0, 0)");
      raw.userVersion = 1;
    }));

    final inspection = await db.select(db.inspections).getSingle();
    expect(inspection.assetCode, 'PUMP-42'); // old data kept
    expect(inspection.note, ''); // schema 2 column
    expect(inspection.serverWonAt, isNull); // schema 5 column

    final op = await db.select(db.outbox).getSingle();
    expect(op.opId, 'op1'); // old data kept
    expect(op.entityId, ''); // schema 3 column

    expect(await db.select(db.syncCursors).get(), isEmpty); // schema 4 table

    await db.close();
  });
}
