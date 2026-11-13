import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/answer_repository.dart';
import '../../data/local/app_database.dart';
import '../../domain/checklist.dart';
import 'question_tile.dart';

/// One inspection: the checklist. Every tap is saved on the phone right away.
class InspectionScreen extends ConsumerWidget {
  const InspectionScreen({super.key, required this.inspection});

  final Inspection inspection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final answers = ref.watch(answersProvider(inspection.id));

    return Scaffold(
      appBar: AppBar(title: Text(inspection.assetCode)),
      body: answers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (saved) => ListView(
          children: [
            for (final question in checklistQuestions)
              QuestionTile(
                question: question,
                answer: saved[question],
                onAnswer: (ok) => ref
                    .read(answerRepositoryProvider)
                    .setAnswer(inspection.id, question, ok),
              ),
          ],
        ),
      ),
    );
  }
}
