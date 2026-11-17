import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpilot/data/inspection_repository.dart';
import 'package:fieldpilot/data/local/app_database.dart';
import 'package:fieldpilot/data/remote/auth_repository.dart';
import 'package:fieldpilot/main.dart';

// Widget tests use fake time, so a real database or server would never answer.
// We give the app ready-made values instead; the real parts have their own tests.
Future<void> pumpApp(
  WidgetTester tester, {
  bool signedIn = true,
  List<Inspection> items = const [],
}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      isSignedInProvider.overrideWith((ref) => Stream.value(signedIn)),
      inspectionsProvider.overrideWith((ref) => Stream.value(items)),
    ],
    child: const FieldPilotApp(),
  ));
  await tester.pump(); // 1: sign-in value arrives, home screen is built
  await tester.pump(); // 2: home screen's list arrives
}

void main() {
  testWidgets('shows the login screen when signed out', (tester) async {
    await pumpApp(tester, signedIn: false);

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Scan asset'), findsNothing);
  });

  testWidgets('shows a message when there are no inspections', (tester) async {
    await pumpApp(tester);

    expect(find.text('No inspections yet'), findsOneWidget);
    expect(find.text('Scan asset'), findsOneWidget);
  });

  testWidgets('lists saved inspections', (tester) async {
    await pumpApp(tester, items: [
      Inspection(
        id: 'i1',
        assetCode: 'PUMP-42',
        status: 'draft',
        version: 0,
        updatedAt: DateTime(2026, 1, 1),
        note: '',
      ),
    ]);

    expect(find.text('PUMP-42'), findsOneWidget);
    expect(find.text('draft'), findsOneWidget);
  });
}
