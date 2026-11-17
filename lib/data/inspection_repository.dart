import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../sync/outbox_writer.dart';
import '../sync/payloads.dart';
import 'local/app_database.dart';
import 'local/database_provider.dart';

/// Saves and reads inspections on the phone. The screens only talk to this class.
class InspectionRepository {
  InspectionRepository(this._db);

  final AppDatabase _db;

  /// Returns the draft inspection of [assetCode]. If there is none, creates one.
  /// This way scanning the same asset twice does not make two drafts.
  Future<Inspection> openOrStartDraft(String assetCode) async {
    final existing = await (_db.select(_db.inspections)
          ..where((i) => i.assetCode.equals(assetCode) & i.status.equals('draft'))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) return existing;

    // Row + outbox entry in one transaction: both saved, or neither.
    return _db.transaction(() async {
      final created = await _db.into(_db.inspections).insertReturning(
            InspectionsCompanion.insert(
              id: const Uuid().v4(), // made on the phone, so it works offline
              assetCode: assetCode,
              status: 'draft',
              updatedAt: DateTime.now(),
            ),
          );
      await _enqueue(created);
      return created;
    });
  }

  /// Saves the free-text note of an inspection.
  Future<void> setNote(String inspectionId, String note) {
    return _db.transaction(() async {
      final changed = await (_db.update(_db.inspections)
            ..where((i) => i.id.equals(inspectionId)))
          .writeReturning(InspectionsCompanion(
        note: Value(note),
        updatedAt: Value(DateTime.now()),
      ));
      await _enqueue(changed.single);
    });
  }

  Future<void> _enqueue(Inspection inspection) => enqueueOp(
        _db,
        entity: 'inspection',
        entityId: inspection.id,
        payload: inspectionPayload(inspection),
      );

  /// All inspections, newest first. Emits again whenever the table changes.
  Stream<List<Inspection>> watchInspections() {
    final query = _db.select(_db.inspections)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    return query.watch();
  }
}

final inspectionRepositoryProvider = Provider<InspectionRepository>(
  (ref) => InspectionRepository(ref.watch(databaseProvider)),
);

final inspectionsProvider = StreamProvider<List<Inspection>>(
  (ref) => ref.watch(inspectionRepositoryProvider).watchInspections(),
);
