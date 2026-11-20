import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/links/app_links.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  const address = 'https://example.com/privacy';

  testWidgets('Settings, About lists the privacy policy once it is set', (
    tester,
  ) async {
    final opener = FakeLinkOpener();
    await pumpRouterApp(
      tester,
      links: opener,
      appLinks: const AppLinks(privacyPolicyUrl: address),
    );
    await goToTab(tester, 'Settings');

    expect(find.text('About'), findsOneWidget);
    await tapText(tester, 'Privacy policy');

    expect(opener.opened, [Uri.parse(address)]);
  });

  testWidgets('Settings has no privacy policy row while no address is set', (
    tester,
  ) async {
    await pumpRouterApp(tester);
    await goToTab(tester, 'Settings');

    expect(find.text('About'), findsOneWidget);
    expect(find.text('Privacy policy'), findsNothing);
  });

  testWidgets('the row stays inside the safe area on a phone with a notch', (
    tester,
  ) async {
    await pumpRouterApp(
      tester,
      appLinks: const AppLinks(privacyPolicyUrl: address),
      screenSize: const Size(360, 700),
      safePadding: const EdgeInsets.only(top: 40, bottom: 34),
    );
    await goToTab(tester, 'Settings');
    // On a small screen the row is below the fold until the list is scrolled.
    await tester.scrollUntilVisible(
      find.text('Privacy policy'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final bottom = tester.getBottomLeft(find.text('Privacy policy')).dy;
    expect(bottom, lessThan(700 - 34));
    expect(tester.takeException(), isNull);
  });
}
