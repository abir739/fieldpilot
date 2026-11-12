import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpilot/data/inspection_repository.dart';
import 'package:fieldpilot/data/local/app_database.dart';
import 'package:fieldpilot/main.dart';

// Widget tests use fake time, so a real database would never answer.
// We give the screen ready-made data instead; the database has its own tests.
Future<void> pumpApp(WidgetTester tester, List<Inspection> items) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [inspectionsProvider.overrideWith((ref) => Stream.value(items))],
    child: const FieldPilotApp(),
  ));
  await tester.pump(); // let the stream deliver its value
}

void main() {
  testWidgets('shows a message when there are no inspections', (tester) async {
    await pumpApp(tester, []);

    expect(find.text('No inspections yet'), findsOneWidget);
    expect(find.text('Scan asset'), findsOneWidget);
  });

  testWidgets('lists saved inspections', (tester) async {
    await pumpApp(tester, [
      Inspection(
        id: 'i1',
        assetCode: 'PUMP-42',
        status: 'draft',
        version: 0,
        updatedAt: DateTime(2026, 1, 1),
      ),
    ]);

    expect(find.text('PUMP-42'), findsOneWidget);
    expect(find.text('draft'), findsOneWidget);
  });
}
