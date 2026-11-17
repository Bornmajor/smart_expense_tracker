import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/security/presentation/lock_session.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  const lockedTitle = 'SpendWise IQ is locked';
  const homeMarker = 'Add your first expense';

  group('launch journey', () {
    testWidgets('goes straight home when the lock is off', (tester) async {
      await pumpRouterApp(tester);

      expect(find.text(lockedTitle), findsNothing);
      expect(find.text(homeMarker), findsOneWidget);
    });

    testWidgets('asks for verification first when the lock is on', (
      tester,
    ) async {
      final authenticator = FakeBiometricAuthenticator(succeeds: false);
      await pumpRouterApp(
        tester,
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

    testWidgets('a first-time user sees welcome before any lock', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
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
        security: security,
        authenticator: FakeBiometricAuthenticator(available: false),
      );
      await openSettings(tester);

      await tester.tap(switchTile());
      await tester.pumpAndSettle();

      expect(
        find.text('Set up a fingerprint or face unlock on this device first'),
        findsOneWidget,
      );
      expect(security.enabled, isFalse);
      expect(tester.widget<SwitchListTile>(switchTile()).value, isFalse);
    });

    testWidgets('stays off when the user fails the check', (tester) async {
      final security = FakeSecurityRepository();
      await pumpRouterApp(
        tester,
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
