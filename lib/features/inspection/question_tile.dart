import 'package:flutter/material.dart';

/// One checklist question with "OK" / "Not OK" buttons.
/// [answer] is null when the question is not answered yet.
class QuestionTile extends StatelessWidget {
  const QuestionTile({
    super.key,
    required this.question,
    required this.answer,
    required this.onAnswer,
  });

  final String question;
  final bool? answer;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(question),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SegmentedButton<bool>(
          emptySelectionAllowed: true, // nothing selected until answered
          selected: {?answer},
          onSelectionChanged: (choice) {
            if (choice.isNotEmpty) onAnswer(choice.first);
          },
          segments: const [
            ButtonSegment(value: true, label: Text('OK'), icon: Icon(Icons.check)),
            ButtonSegment(value: false, label: Text('Not OK'), icon: Icon(Icons.close)),
          ],
        ),
      ),
    );
  }
}
