import 'package:drift/drift.dart';

import '../data/local/app_database.dart';

/// Translations between local rows and the server's JSON rows.
/// Server keys use the server's column names (snake_case).

/// A server inspection row, ready to save on the phone.
InspectionsCompanion inspectionFromServer(Map<String, dynamic> row) =>
    InspectionsCompanion(
      id: Value(row['id'] as String),
      assetCode: Value(row['asset_code'] as String),
      status: Value(row['status'] as String),
      note: Value(row['note'] as String),
      version: Value(row['version'] as int),
      updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
    );

/// A server answer row, ready to save on the phone.
AnswersCompanion answerFromServer(Map<String, dynamic> row) => AnswersCompanion(
      id: Value(row['id'] as String),
      inspectionId: Value(row['inspection_id'] as String),
      question: Value(row['question'] as String),
      ok: Value(row['ok'] as bool),
    );

/// What we send to the server for each kind of row.

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
