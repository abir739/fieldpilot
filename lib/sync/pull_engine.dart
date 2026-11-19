import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/app_database.dart';
import '../data/local/database_provider.dart';
import 'payloads.dart';
import 'pull_api.dart';

/// Brings server changes down to the phone.
///
/// Rules:
/// - Ask only for rows changed after our bookmark (cursor), then move it.
/// - Ask from a few seconds BEFORE the bookmark: a write that was still in
///   progress during the last pull could carry a slightly older time.
///   Saving a row twice is harmless, missing one is not.
/// - Skip rows we have unsent edits for: the push decides those (and if the
///   server wins, push already takes the server copy).
class PullEngine {
  PullEngine(this._db, this._api);

  final AppDatabase _db;
  final PullApi _api;

  static const overlap = Duration(seconds: 5);

  /// Throws when the network or server fails (nothing is half-saved).
  Future<void> pullAll() async {
    // Parents first: an answer needs its inspection.
    await _pull('inspections', 'inspection', _db.inspections, inspectionFromServer);
    await _pull('answers', 'answer', _db.answers, answerFromServer);
  }

  Future<void> _pull<T extends Table, R>(
    String serverTable,
    String entity,
    TableInfo<T, R> localTable,
    Insertable<R> Function(Map<String, dynamic>) toLocal,
  ) async {
    final cursor = await _cursor(serverTable);
    final rows = await _api.changedSince(serverTable, cursor?.subtract(overlap));
    if (rows.isEmpty) return;

    await _db.transaction(() async {
      final unsent = await _unsentIds(entity);
      for (final row in rows) {
        if (unsent.contains(row['id'])) continue;
        await _db.into(localTable).insertOnConflictUpdate(toLocal(row));
      }
      final newest = DateTime.parse(rows.last['synced_at'] as String);
      await _db.into(_db.syncCursors).insertOnConflictUpdate(
            SyncCursorsCompanion.insert(name: serverTable, seenUntil: newest),
          );
    });
  }

  Future<DateTime?> _cursor(String serverTable) async {
    final row = await (_db.select(_db.syncCursors)
          ..where((c) => c.name.equals(serverTable)))
        .getSingleOrNull();
    return row?.seenUntil;
  }

  Future<Set<String>> _unsentIds(String entity) async {
    final ops = await (_db.select(_db.outbox)
          ..where((o) => o.entity.equals(entity)))
        .get();
    return {for (final op in ops) op.entityId};
  }
}

final pullEngineProvider = Provider<PullEngine>(
  (ref) => PullEngine(ref.watch(databaseProvider), ref.watch(pullApiProvider)),
);
