import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpilot/data/answer_repository.dart';
import 'package:fieldpilot/data/local/app_database.dart';
import 'package:fieldpilot/data/photo_repository.dart';
import 'package:fieldpilot/domain/checklist.dart';
import 'package:fieldpilot/features/inspection/inspection_screen.dart';

void main() {
  final inspection = Inspection(
    id: 'i1',
    assetCode: 'PUMP-42',
    status: 'draft',
    version: 0,
    updatedAt: DateTime(2026, 1, 1),
    note: '',
  );

  testWidgets('shows the asset code and every checklist question', (tester) async {
    await tester.pumpWidget(ProviderScope(
      // Fake answers: widget tests can't wait for a real database.
      overrides: [
        answersProvider('i1').overrideWith((ref) => Stream.value({'No leaks': true})),
        photosProvider('i1').overrideWith((ref) => Stream.value([])),
      ],
      child: MaterialApp(home: InspectionScreen(inspection: inspection)),
    ));
    await tester.pump();

    expect(find.text('PUMP-42'), findsOneWidget);
    for (final question in checklistQuestions) {
      expect(find.text(question), findsOneWidget);
    }
    // The page and the note box can both scroll: scroll the page (the first one).
    final page = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Take photo'), 200, scrollable: page);
    expect(find.text('Take photo'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Note'), 200, scrollable: page);
    expect(find.text('Note'), findsOneWidget);
  });
}
