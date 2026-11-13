import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpilot/data/answer_repository.dart';
import 'package:fieldpilot/data/inspection_repository.dart';
import 'package:fieldpilot/data/local/app_database.dart';

void main() {
  late AppDatabase db;
  late AnswerRepository answers;
  late String inspectionId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    answers = AnswerRepository(db);
    inspectionId = await InspectionRepository(db).startInspection('PUMP-42');
  });
  tearDown(() => db.close());

  test('saves an answer', () async {
    await answers.setAnswer(inspectionId, 'No leaks', true);

    expect(await answers.watchAnswers(inspectionId).first, {'No leaks': true});
  });

  test('answering again replaces the old answer (no duplicate rows)', () async {
    await answers.setAnswer(inspectionId, 'No leaks', true);
    await answers.setAnswer(inspectionId, 'No leaks', false);

    expect(await answers.watchAnswers(inspectionId).first, {'No leaks': false});
    expect(await db.select(db.answers).get(), hasLength(1));
  });

  test('only returns answers of the given inspection', () async {
    final otherId = await InspectionRepository(db).startInspection('TANK-1');
    await answers.setAnswer(otherId, 'No leaks', false);

    expect(await answers.watchAnswers(inspectionId).first, isEmpty);
  });
}
