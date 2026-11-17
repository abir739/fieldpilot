import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/database_provider.dart';

/// How many changes are still waiting to be sent. Updates live.
final pendingOpsProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  final count = db.outbox.opId.count();
  final query = db.selectOnly(db.outbox)..addColumns([count]);
  return query.watchSingle().map((row) => row.read(count) ?? 0);
});
