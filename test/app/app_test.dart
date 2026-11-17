import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expense_tracker/app/app.dart';
import 'package:smart_expense_tracker/core/database/app_database.dart';

import '../support/fakes.dart';

/// Runs the real app wiring (preferences, router, lock) for the screens that
/// do not read from the database. Screens that do are covered with fake
/// repositories in the flow tests, because drift's live queries do not
/// complete inside the widget tester's fake clock.
void main() {
  // Each test builds its own (unopened) in-memory database.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<void> pumpApp(
    WidgetTester tester,
    Map<String, Object> savedValues, {
    FakeBiometricAuthenticator? authenticator,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(savedValues);
    final preferences = await SharedPreferences.getInstance();
    // Never queried in these tests, so it is never opened and needs no closing.
    final database = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      SpendWiseApp(
        database: database,
        preferences: preferences,
        biometricAuthenticator: authenticator ?? FakeBiometricAuthenticator(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('first launch starts with the welcome screen', (tester) async {
    await pumpApp(tester, {});

    expect(find.text('Welcome to SpendWise IQ'), findsOneWidget);
  });

  testWidgets('a returning user with the lock on is asked to verify', (
    tester,
  ) async {
    final authenticator = FakeBiometricAuthenticator(succeeds: false);

    await pumpApp(tester, {
      'onboarding_completed': true,
      'biometric_lock_enabled': true,
    }, authenticator: authenticator);

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('SpendWise IQ is locked'), findsOneWidget);
    expect(authenticator.authenticateCalls, 1);
  });
}
