import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local/app_database.dart';
import 'local/database_provider.dart';

/// Saves and reads checklist answers on the phone.
class AnswerRepository {
  AnswerRepository(this._db);

  final AppDatabase _db;

  /// Saves the answer to [question]. Answering again replaces the old answer.
  Future<void> setAnswer(String inspectionId, String question, bool ok) {
    return _db.into(_db.answers).insertOnConflictUpdate(AnswersCompanion.insert(
          // Same inspection + same question = same id, so a new tap updates the row.
          id: '$inspectionId|$question',
          inspectionId: inspectionId,
          question: question,
          ok: ok,
        ));
  }

  /// Answers of one inspection as {question: ok}. Emits again on every change.
  Stream<Map<String, bool>> watchAnswers(String inspectionId) {
    final query = _db.select(_db.answers)
      ..where((a) => a.inspectionId.equals(inspectionId));
    return query.watch().map(
          (rows) => {for (final row in rows) row.question: row.ok},
        );
  }
}

final answerRepositoryProvider = Provider<AnswerRepository>(
  (ref) => AnswerRepository(ref.watch(databaseProvider)),
);

final answersProvider = StreamProvider.family<Map<String, bool>, String>(
  (ref, inspectionId) =>
      ref.watch(answerRepositoryProvider).watchAnswers(inspectionId),
);
