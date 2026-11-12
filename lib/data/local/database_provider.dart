import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// The one local database for the whole app. Tests replace it with an in-memory one.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
