import '../data/local/app_database.dart';

/// What we send to the server for each kind of row.
/// Keys use the server's column names (snake_case).

Map<String, Object?> inspectionPayload(Inspection i) => {
      'id': i.id,
      'asset_code': i.assetCode,
      'status': i.status,
      'note': i.note,
      'version': i.version, // the server version this change is based on
      'updated_at': i.updatedAt.toUtc().toIso8601String(),
    };

Map<String, Object?> answerPayload(Answer a) => {
      'id': a.id,
      'inspection_id': a.inspectionId,
      'question': a.question,
      'ok': a.ok,
    };
