import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Inspections, Answers, Photos, Findings, Outbox])
class AppDatabase extends _$AppDatabase {
  /// Pass an executor in tests (e.g. an in-memory database).
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'fieldpilot'));

  @override
  int get schemaVersion => 1;
}
