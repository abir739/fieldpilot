import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpilot/data/local/app_database.dart';

void main() {
  test('upgrading from schema 1 keeps inspections and adds an empty note', () async {
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
      raw.execute("INSERT INTO inspections VALUES ('i1', 'PUMP-42', 'draft', 0, 0)");
      raw.userVersion = 1;
    }));

    final saved = await db.select(db.inspections).getSingle();

    expect(saved.assetCode, 'PUMP-42'); // old data kept
    expect(saved.note, ''); // new column added with its default
    await db.close();
  });
}
