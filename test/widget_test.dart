import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fieldpilot/main.dart';

void main() {
  testWidgets('home screen shows the scan button', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FieldPilotApp()));

    expect(find.text('FieldPilot'), findsOneWidget);
    expect(find.text('Scan asset'), findsOneWidget);
  });
}
