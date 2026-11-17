import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/onboarding/presentation/widgets/step_progress_bar.dart';
import 'package:smart_expense_tracker/features/onboarding/presentation/widgets/welcome_hero.dart';
import 'package:smart_expense_tracker/shared/widgets/app_logo.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

/// Every screen must keep its content out of the notch (top), the gesture bar
/// (bottom) and side cutouts. These tests simulate them and check positions.
void main() {
  const top = 48.0;
  const bottom = 34.0;
  const side = 44.0;
  const phone = Size(360, 780);
  const notch = EdgeInsets.fromLTRB(0, top, 0, bottom);
  const landscapeNotch = EdgeInsets.fromLTRB(side, top, side, bottom);

  double bottomLimit(Size size) => size.height - bottom;

  Finder inAppBar(String text) =>
      find.descendant(of: find.byType(AppBar), matching: find.text(text));

  group('welcome screen', () {
    testWidgets(
      'keeps the logo and button clear of the notch and gesture bar',
      (tester) async {
        await pumpRouterApp(
          tester,
          onboarding: FakeOnboardingRepository(),
          screenSize: phone,
          safePadding: notch,
        );

        expect(
          tester.getTopLeft(find.byType(AppLogo)).dy,
          greaterThanOrEqualTo(top),
        );
        expect(
          tester.getBottomLeft(find.byType(FilledButton)).dy,
          lessThanOrEqualTo(bottomLimit(phone)),
        );
      },
    );

    testWidgets('the colored area still reaches the top edge', (tester) async {
      await pumpRouterApp(
        tester,
        onboarding: FakeOnboardingRepository(),
        screenSize: phone,
        safePadding: notch,
      );

      expect(tester.getTopLeft(find.byType(WelcomeHero)).dy, 0);
    });
  });

  group('onboarding', () {
    Future<void> openOnboarding(WidgetTester tester, EdgeInsets padding) async {
      await pumpRouterApp(
        tester,
        onboarding: FakeOnboardingRepository(),
        screenSize: phone,
        safePadding: padding,
      );
      await tapText(tester, 'Get started');
    }

    testWidgets(
      'keeps the progress bar, picture and buttons in the safe area',
      (tester) async {
        await openOnboarding(tester, notch);

        expect(
          tester.getTopLeft(find.byType(StepProgressBar)).dy,
          greaterThanOrEqualTo(top),
        );
        expect(
          tester.getTopLeft(find.byType(Image)).dy,
          greaterThanOrEqualTo(top),
        );
        expect(
          tester.getBottomLeft(find.widgetWithText(TextButton, 'Skip')).dy,
          lessThanOrEqualTo(bottomLimit(phone)),
        );
      },
    );

    testWidgets('keeps the text clear of the buttons with a gesture bar', (
      tester,
    ) async {
      await openOnboarding(tester, notch);

      final text = tester
          .getBottomLeft(find.textContaining('Scan a receipt'))
          .dy;
      expect(
        text,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(FilledButton)).dy),
      );
    });

    testWidgets('keeps content out of side cutouts', (tester) async {
      await openOnboarding(tester, landscapeNotch);

      expect(
        tester.getTopLeft(find.byType(StepProgressBar)).dx,
        greaterThanOrEqualTo(side),
      );
      expect(
        tester.getTopRight(find.byType(StepProgressBar)).dx,
        lessThanOrEqualTo(phone.width - side),
      );
      expect(
        tester.getTopLeft(find.text('Add expenses your way')).dx,
        greaterThanOrEqualTo(side),
      );
    });
  });

  group('lock screen', () {
    testWidgets('keeps the logo and Unlock button in the safe area', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
        security: FakeSecurityRepository(enabled: true),
        authenticator: FakeBiometricAuthenticator(succeeds: false),
        screenSize: phone,
        safePadding: notch,
      );

      expect(
        tester.getTopLeft(find.byType(AppLogo)).dy,
        greaterThanOrEqualTo(top),
      );
      expect(
        tester.getBottomLeft(find.byType(FilledButton)).dy,
        lessThanOrEqualTo(bottomLimit(phone)),
      );
    });
  });

  group('main tabs', () {
    testWidgets(
      'titles sit below the notch and the bar above the gesture bar',
      (tester) async {
        await pumpRouterApp(tester, screenSize: phone, safePadding: notch);

        expect(
          tester.getTopLeft(inAppBar('Expenses')).dy,
          greaterThanOrEqualTo(top),
        );
        expect(
          tester
              .getBottomLeft(
                find.descendant(
                  of: find.byType(NavigationBar),
                  matching: find.text('Settings'),
                ),
              )
              .dy,
          lessThanOrEqualTo(bottomLimit(phone)),
        );

        await goToTab(tester, 'Summary');
        expect(
          tester.getTopLeft(inAppBar('Summary')).dy,
          greaterThanOrEqualTo(top),
        );

        await goToTab(tester, 'Settings');
        expect(
          tester.getTopLeft(inAppBar('Settings')).dy,
          greaterThanOrEqualTo(top),
        );
      },
    );

    testWidgets('page content stays out of side cutouts', (tester) async {
      await pumpRouterApp(
        tester,
        screenSize: phone,
        safePadding: landscapeNotch,
      );
      await goToTab(tester, 'Settings');

      expect(
        tester.getTopLeft(find.text('Appearance')).dx,
        greaterThanOrEqualTo(side),
      );
      expect(
        tester.getTopRight(find.byType(Card).first).dx,
        lessThanOrEqualTo(phone.width - side),
      );
    });
  });

  group('add expense form', () {
    testWidgets('the Save button can scroll clear of the gesture bar', (
      tester,
    ) async {
      const shortPhone = Size(360, 460);
      await pumpRouterApp(tester, screenSize: shortPhone, safePadding: notch);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tapText(tester, 'Enter manually');

      expect(
        tester.getTopLeft(inAppBar('Add expense')).dy,
        greaterThanOrEqualTo(top),
      );

      final save = find.widgetWithText(FilledButton, 'Save expense');
      // The list builds items lazily, so scroll until the button exists.
      await tester.scrollUntilVisible(
        save,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        tester.getBottomLeft(save).dy,
        lessThanOrEqualTo(bottomLimit(shortPhone)),
      );
    });

    testWidgets('the form stays out of side cutouts', (tester) async {
      await pumpRouterApp(
        tester,
        screenSize: phone,
        safePadding: landscapeNotch,
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tapText(tester, 'Enter manually');

      final field = find.widgetWithText(TextField, 'Amount');
      expect(tester.getTopLeft(field).dx, greaterThanOrEqualTo(side));
      expect(
        tester.getTopRight(field).dx,
        lessThanOrEqualTo(phone.width - side),
      );
    });
  });
}
