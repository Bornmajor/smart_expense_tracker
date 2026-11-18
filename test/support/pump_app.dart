import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/app/app_router.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:smart_expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:smart_expense_tracker/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:smart_expense_tracker/features/security/domain/repositories/biometric_authenticator.dart';
import 'package:smart_expense_tracker/features/security/domain/usecases/enable_biometric_lock.dart';
import 'package:smart_expense_tracker/features/security/presentation/cubit/security_cubit.dart';
import 'package:smart_expense_tracker/features/security/presentation/lock_session.dart';
import 'package:smart_expense_tracker/features/settings/presentation/cubit/settings_cubit.dart';

import 'fakes.dart';

/// Pumps the real router and pages with fake repositories.
/// Returns the lock session so tests can simulate leaving and returning.
Future<LockSession> pumpRouterApp(
  WidgetTester tester, {
  FakeOnboardingRepository? onboarding,
  FakeExpenseRepository? expenses,
  FakeCategoryRepository? categories,
  FakeSettingsRepository? settings,
  FakeSecurityRepository? security,
  FakeBiometricAuthenticator? authenticator,
  LockSession? lockSession,
  Size screenSize = const Size(800, 1600),
  EdgeInsets safePadding = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = screenSize;
  // Simulates a notch and gesture bar (the device pixel ratio is 1 below).
  final insets = FakeViewPadding(
    left: safePadding.left,
    top: safePadding.top,
    right: safePadding.right,
    bottom: safePadding.bottom,
  );
  tester.view.padding = insets;
  tester.view.viewPadding = insets;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final onboardingRepo =
      onboarding ?? FakeOnboardingRepository(completed: true);
  final securityRepo = security ?? FakeSecurityRepository();
  final auth = authenticator ?? FakeBiometricAuthenticator();
  final settingsRepo = settings ?? FakeSettingsRepository();
  final session =
      lockSession ?? LockSession(enabled: securityRepo.isBiometricEnabled);

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OnboardingRepository>.value(value: onboardingRepo),
        RepositoryProvider<ExpenseRepository>.value(
          value: expenses ?? FakeExpenseRepository(),
        ),
        RepositoryProvider<CategoryRepository>.value(
          value: categories ?? FakeCategoryRepository(),
        ),
        RepositoryProvider<BiometricAuthenticator>.value(value: auth),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SettingsCubit(settingsRepo)),
          BlocProvider(
            create: (_) => SecurityCubit(
              securityRepo,
              EnableBiometricLock(securityRepo, auth),
              session,
            ),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: createRouter(
            onboarding: onboardingRepo,
            lockSession: session,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return session;
}

Future<void> tapText(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Taps a bottom navigation tab (the label also appears as a page title).
Future<void> goToTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}
