import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

/// The temporary OCR test screen. Tests run in debug mode, so it is there.
void main() {
  testWidgets('Settings has a Developer entry that opens the OCR test', (
    tester,
  ) async {
    await pumpRouterApp(tester);
    await goToTab(tester, 'Settings');

    expect(find.text('Developer'), findsOneWidget);
    await tapText(tester, 'OCR test');

    expect(find.text('OCR test (temporary)'), findsOneWidget);
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose photo'), findsOneWidget);
    expect(find.text('Original size'), findsOneWidget);
  });
}
