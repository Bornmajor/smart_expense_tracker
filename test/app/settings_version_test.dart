import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('Settings shows which version of the app is installed', (
    tester,
  ) async {
    await pumpRouterApp(tester);
    await goToTab(tester, 'Settings');

    expect(find.text('Version'), findsOneWidget);
    expect(find.text('1.2.3 (build 45)'), findsOneWidget);
  });
}
