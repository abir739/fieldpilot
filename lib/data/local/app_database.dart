import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
    tables: [Inspections, Answers, Photos, Findings, Outbox, SyncCursors])
class AppDatabase extends _$AppDatabase {
  /// Pass an executor in tests (e.g. an in-memory database).
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'fieldpilot'));

  /// Bump this every time a table changes, and add a step in [migration].
  @override
  int get schemaVersion => 5;

  /// Upgrades a database that already exists on a phone, keeping its data.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.addColumn(inspections, inspections.note);
          if (from < 3) await m.addColumn(outbox, outbox.entityId);
          if (from < 4) await m.createTable(syncCursors);
          if (from < 5) await m.addColumn(inspections, inspections.serverWonAt);
        },
      );
}
