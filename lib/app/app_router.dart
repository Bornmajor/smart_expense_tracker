import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/categories/domain/repositories/category_repository.dart';
import '../features/categories/presentation/cubit/categories_cubit.dart';
import '../features/dashboard/presentation/cubit/summary_cubit.dart';
import '../features/dashboard/presentation/pages/summary_page.dart';
import '../features/expenses/domain/repositories/expense_repository.dart';
import '../features/expenses/domain/usecases/save_expense.dart';
import '../features/expenses/presentation/cubit/add_expense_cubit.dart';
import '../features/expenses/presentation/cubit/expense_list_cubit.dart';
import '../features/expenses/presentation/pages/add_expense_page.dart';
import '../features/expenses/presentation/pages/expense_list_page.dart';
import '../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/onboarding/presentation/pages/welcome_page.dart';
import '../features/security/domain/repositories/biometric_authenticator.dart';
import '../features/security/presentation/cubit/lock_cubit.dart';
import '../features/security/presentation/lock_session.dart';
import '../features/security/presentation/pages/lock_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import 'app_routes.dart';
import 'app_shell.dart';

/// The app's navigation.
///
/// Journey on launch:
///  1. First time: welcome -> onboarding (once) -> home.
///  2. Afterwards: home, or the lock screen first if the user turned on the
///     biometric lock.
GoRouter createRouter({
  required OnboardingRepository onboarding,
  required LockSession lockSession,
}) => GoRouter(
  initialLocation: AppRoutes.expenses,
  refreshListenable: lockSession,
  redirect: (context, state) {
    final location = state.matchedLocation;
    final inIntro =
        location == AppRoutes.welcome || location == AppRoutes.onboarding;

    if (!onboarding.isCompleted) return inIntro ? null : AppRoutes.welcome;

    if (lockSession.isLocked) {
      return location == AppRoutes.lock ? null : AppRoutes.lock;
    }
    if (inIntro || location == AppRoutes.lock) return AppRoutes.expenses;
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => BlocProvider(
        create: (_) => OnboardingCubit(context.read<OnboardingRepository>()),
        child: const OnboardingPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.lock,
      builder: (context, state) => BlocProvider(
        create: (_) =>
            LockCubit(context.read<BiometricAuthenticator>(), lockSession),
        child: const LockPage(),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.expenses,
              builder: (context, state) => BlocProvider(
                create: (_) =>
                    ExpenseListCubit(context.read<ExpenseRepository>()),
                child: const ExpenseListPage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.summary,
              builder: (context, state) => MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) =>
                        SummaryCubit(context.read<ExpenseRepository>()),
                  ),
                  BlocProvider(
                    create: (_) =>
                        CategoriesCubit(context.read<CategoryRepository>()),
                  ),
                ],
                child: const SummaryPage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.addExpense,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                AddExpenseCubit(SaveExpense(context.read<ExpenseRepository>())),
          ),
          BlocProvider(
            create: (_) => CategoriesCubit(context.read<CategoryRepository>()),
          ),
        ],
        child: const AddExpensePage(),
      ),
    ),
  ],
);
