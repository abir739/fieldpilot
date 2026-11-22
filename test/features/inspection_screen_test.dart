import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drift/drift.dart' show Value;
import 'package:fieldpilot/data/answer_repository.dart';
import 'package:fieldpilot/data/inspection_repository.dart';
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

  // Fake values: widget tests can't wait for a real database.
  Future<void> pumpScreen(WidgetTester tester, Inspection live) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        inspectionProvider('i1').overrideWith((ref) => Stream.value(live)),
        answersProvider('i1').overrideWith((ref) => Stream.value({'No leaks': true})),
        photosProvider('i1').overrideWith((ref) => Stream.value([])),
      ],
      child: MaterialApp(home: InspectionScreen(inspection: inspection)),
    ));
    await tester.pump();
  }

  testWidgets('no conflict: no banner', (tester) async {
    await pumpScreen(tester, inspection);
    expect(find.text('Got it'), findsNothing);
  });

  testWidgets('server won: banner and the server note are shown', (tester) async {
    await pumpScreen(
      tester,
      inspection.copyWith(
        note: 'changed on server',
        serverWonAt: Value(DateTime(2026, 1, 2)),
      ),
    );
    expect(find.text('Got it'), findsOneWidget);
    expect(find.textContaining('server version was kept'), findsOneWidget);

    final page = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('changed on server'), 200, scrollable: page);
    expect(find.text('changed on server'), findsOneWidget); // note box shows it
  });

  testWidgets('shows the asset code and every checklist question', (tester) async {
    await pumpScreen(tester, inspection);

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
