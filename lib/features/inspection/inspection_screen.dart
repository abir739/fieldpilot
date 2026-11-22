import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/answer_repository.dart';
import '../../data/inspection_repository.dart';
import '../../data/local/app_database.dart';
import '../../domain/checklist.dart';
import 'conflict_banner.dart';
import 'note_field.dart';
import 'photo_section.dart';
import 'question_tile.dart';

/// One inspection: the checklist. Every tap is saved on the phone right away.
class InspectionScreen extends ConsumerWidget {
  const InspectionScreen({super.key, required this.inspection});

  /// The inspection as it was when opened. The screen then follows the live
  /// row, so changes from sync (e.g. the server's copy) show up at once.
  final Inspection inspection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(inspectionProvider(inspection.id)).value ?? inspection;
    final answers = ref.watch(answersProvider(inspection.id));

    return Scaffold(
      appBar: AppBar(title: Text(live.assetCode)),
      body: answers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (saved) => ListView(
          children: [
            if (live.serverWonAt != null)
              ConflictBanner(
                onDismiss: () => ref
                    .read(inspectionRepositoryProvider)
                    .dismissServerWon(live.id),
              ),
            for (final question in checklistQuestions)
              QuestionTile(
                question: question,
                answer: saved[question],
                onAnswer: (ok) => ref
                    .read(answerRepositoryProvider)
                    .setAnswer(live.id, question, ok),
              ),
            const Divider(),
            PhotoSection(inspectionId: live.id),
            NoteField(
              // A new conflict means new text from the server: rebuild the
              // box with it. Normal syncs don't change the key, so typing is
              // never interrupted.
              key: ValueKey(live.serverWonAt),
              inspectionId: live.id,
              initialNote: live.note,
            ),
          ],
        ),
      ),
    );
  }
}
