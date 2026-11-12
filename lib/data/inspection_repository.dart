import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'local/app_database.dart';
import 'local/database_provider.dart';

/// Saves and reads inspections on the phone. The screens only talk to this class.
class InspectionRepository {
  InspectionRepository(this._db);

  final AppDatabase _db;

  /// Creates a new draft inspection for [assetCode] and returns its id.
  Future<String> startInspection(String assetCode) async {
    final id = const Uuid().v4(); // made on the phone, so it works offline
    await _db.into(_db.inspections).insert(InspectionsCompanion.insert(
          id: id,
          assetCode: assetCode,
          status: 'draft',
          updatedAt: DateTime.now(),
        ));
    return id;
  }

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
