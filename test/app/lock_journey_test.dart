import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/security/domain/entities/auth_outcome.dart';
import 'package:smart_expense_tracker/features/security/presentation/lock_session.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  const lockedTitle = 'SpendWise IQ is locked';
  // The first thing on Home when the app has no expenses yet.
  const homeMarker = 'Let\'s add your first expense';

  group('launch journey', () {
    testWidgets('goes straight home when the lock is off', (tester) async {
      await pumpRouterApp(tester, startOnHome: true);

      expect(find.text(lockedTitle), findsNothing);
      expect(find.text(homeMarker), findsOneWidget);
    });

    testWidgets('asks for verification first when the lock is on', (
      tester,
    ) async {
      final authenticator = FakeBiometricAuthenticator(succeeds: false);
      await pumpRouterApp(
        tester,
        startOnHome: true,
        security: FakeSecurityRepository(enabled: true),
        authenticator: authenticator,
      );

      expect(find.text(lockedTitle), findsOneWidget);
      expect(find.text(homeMarker), findsNothing);
      expect(authenticator.authenticateCalls, 1);
    });

    testWidgets('lands on home once verification succeeds', (tester) async {
      await pumpRouterApp(
        tester,
        startOnHome: true,
        security: FakeSecurityRepository(enabled: true),
      );

      expect(find.text(lockedTitle), findsNothing);
      expect(find.text(homeMarker), findsOneWidget);
    });

    testWidgets('a failed check shows feedback and can be retried', (
      tester,
    ) async {
      final authenticator = FakeBiometricAuthenticator(succeeds: false);
      await pumpRouterApp(
        tester,
        startOnHome: true,
        security: FakeSecurityRepository(enabled: true),
        authenticator: authenticator,
      );
      expect(
        find.text('Couldn\'t verify it\'s you. Try again.'),
        findsOneWidget,
      );

      authenticator.succeeds = true;
      await tapText(tester, 'Unlock');

      expect(authenticator.authenticateCalls, 2);
      expect(find.text(lockedTitle), findsNothing);
      expect(find.text(homeMarker), findsOneWidget);
    });

    testWidgets('a phone that cannot check the user still lets them in', (
      tester,
    ) async {
      // For example the screen lock was removed after the app lock was on.
      final security = FakeSecurityRepository(enabled: true);
      await pumpRouterApp(
        tester,
        startOnHome: true,
        security: security,
        authenticator: FakeBiometricAuthenticator()
          ..outcome = AuthOutcome.unavailable,
      );
      expect(find.text(lockedTitle), findsOneWidget);
      expect(find.textContaining('can\'t check it\'s you'), findsOneWidget);

      await tapText(tester, 'Turn off app lock');
      // It asks first, because turning the lock off lets anyone in.
      expect(find.text('Turn off the app lock?'), findsOneWidget);
      await tapText(tester, 'Turn off');

      expect(find.text(lockedTitle), findsNothing);
      expect(find.text(homeMarker), findsOneWidget);
      expect(security.enabled, isFalse);
    });

    testWidgets('a first-time user sees welcome before any lock', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
        startOnHome: true,
        onboarding: FakeOnboardingRepository(),
        security: FakeSecurityRepository(enabled: true),
      );

      expect(find.text('Welcome to SpendWise IQ'), findsOneWidget);
      expect(find.text(lockedTitle), findsNothing);
    });
  });

  group('locking again', () {
    testWidgets('locks after a long time away, not after a short trip', (
      tester,
    ) async {
      var clock = DateTime(2026, 11, 17, 12);
      final authenticator = FakeBiometricAuthenticator();
      final session = LockSession(enabled: true, now: () => clock);
      await pumpRouterApp(
        tester,
        startOnHome: true,
        security: FakeSecurityRepository(enabled: true),
        authenticator: authenticator,
        lockSession: session,
      );
      expect(find.text(homeMarker), findsOneWidget);
      authenticator.succeeds = false;

      session.didEnterBackground();
      clock = clock.add(const Duration(seconds: 5));
      session.didReturnToForeground();
      await tester.pumpAndSettle();
      expect(find.text(homeMarker), findsOneWidget);

      session.didEnterBackground();
      clock = clock.add(const Duration(minutes: 2));
      session.didReturnToForeground();
      await tester.pumpAndSettle();
      expect(find.text(lockedTitle), findsOneWidget);
    });
  });

  group('Settings switch', () {
    Future<void> openSettings(WidgetTester tester) =>
        goToTab(tester, 'Settings');

    Finder switchTile() => find.byType(SwitchListTile);

    testWidgets('turns the lock on after the device confirms the user', (
      tester,
    ) async {
      final security = FakeSecurityRepository();
      final session = await pumpRouterApp(tester, security: security);
      await openSettings(tester);

      await tester.tap(switchTile());
      await tester.pumpAndSettle();

      expect(find.text('Biometric lock turned on'), findsOneWidget);
      expect(security.enabled, isTrue);
      expect(tester.widget<SwitchListTile>(switchTile()).value, isTrue);
      expect(session.isLocked, isFalse);
    });

    testWidgets('explains when no fingerprint or face is set up', (
      tester,
    ) async {
      final security = FakeSecurityRepository();
      await pumpRouterApp(
        tester,
        startOnHome: true,
        security: security,
        authenticator: FakeBiometricAuthenticator(available: false),
      );
      await openSettings(tester);

      await tester.tap(switchTile());
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Set up a screen lock, fingerprint or face on this phone first',
        ),
        findsOneWidget,
      );
      expect(security.enabled, isFalse);
      expect(tester.widget<SwitchListTile>(switchTile()).value, isFalse);
    });

    testWidgets('stays off when the user fails the check', (tester) async {
      final security = FakeSecurityRepository();
      await pumpRouterApp(
        tester,
        startOnHome: true,
        security: security,
        authenticator: FakeBiometricAuthenticator(succeeds: false),
      );
      await openSettings(tester);

      await tester.tap(switchTile());
      await tester.pumpAndSettle();

      expect(
        find.text('Couldn\'t verify it\'s you. Try again.'),
        findsOneWidget,
      );
      expect(security.enabled, isFalse);
    });

    testWidgets('turns the lock off', (tester) async {
      final security = FakeSecurityRepository(enabled: true);
      await pumpRouterApp(tester, security: security);
      await openSettings(tester);

      await tester.tap(switchTile());
      await tester.pumpAndSettle();

      expect(find.text('Biometric lock turned off'), findsOneWidget);
      expect(security.enabled, isFalse);
    });
  });
}
