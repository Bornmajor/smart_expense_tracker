import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/budgets/domain/repositories/budget_repository.dart';
import '../features/budgets/domain/usecases/remove_budget.dart';
import '../features/budgets/domain/usecases/set_budget.dart';
import '../features/budgets/presentation/cubit/budgets_cubit.dart';
import '../features/budgets/presentation/pages/budgets_page.dart';
import '../features/categories/domain/repositories/category_repository.dart';
import '../features/categories/domain/usecases/create_category.dart';
import '../features/categories/domain/usecases/delete_category.dart';
import '../features/categories/domain/usecases/find_or_create_category.dart';
import '../features/categories/domain/usecases/rename_category.dart';
import '../features/categories/presentation/cubit/categories_cubit.dart';
import '../features/categories/presentation/cubit/category_actions_cubit.dart';
import '../features/categories/presentation/pages/categories_page.dart';
import '../features/dashboard/presentation/cubit/summary_cubit.dart';
import '../features/dashboard/presentation/pages/summary_page.dart';
import '../features/expenses/domain/entities/expense.dart';
import '../features/expenses/domain/repositories/expense_repository.dart';
import '../features/expenses/domain/usecases/save_expense.dart';
import '../features/expenses/domain/usecases/update_expense.dart';
import '../features/expenses/domain/usecases/vendor_category_memory.dart';
import '../features/expenses/presentation/cubit/expense_form_cubit.dart';
import '../features/expenses/presentation/cubit/expense_list_cubit.dart';
import '../features/expenses/presentation/pages/expense_form_page.dart';
import '../features/expenses/presentation/pages/expense_list_page.dart';
import '../features/export/domain/usecases/export_month.dart';
import '../features/export/presentation/cubit/export_cubit.dart';
import '../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../features/recurring/domain/entities/recurring_rule.dart';
import '../features/recurring/domain/repositories/recurring_repository.dart';
import '../features/recurring/domain/usecases/generate_due_expenses.dart';
import '../features/recurring/domain/usecases/save_recurring_rule.dart';
import '../features/recurring/presentation/cubit/recurring_cubit.dart';
import '../features/recurring/presentation/cubit/recurring_form_cubit.dart';
import '../features/recurring/presentation/pages/recurring_form_page.dart';
import '../features/recurring/presentation/pages/recurring_page.dart';
import '../features/scan/debug/ocr_debug_page.dart';
import '../features/scan/domain/entities/receipt_source.dart';
import '../features/scan/domain/entities/scan_result.dart';
import '../features/scan/domain/repositories/receipt_photo_source.dart';
import '../features/scan/domain/repositories/receipt_text_reader.dart';
import '../features/scan/domain/usecases/scan_receipt.dart';
import '../features/scan/presentation/cubit/scan_cubit.dart';
import '../features/scan/presentation/pages/scan_page.dart';
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
              builder: (context, state) => MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) =>
                        ExpenseListCubit(context.read<ExpenseRepository>()),
                  ),
                  // Category names for the rows.
                  BlocProvider(
                    create: (_) =>
                        CategoriesCubit(context.read<CategoryRepository>()),
                  ),
                ],
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
                    create: (_) => SummaryCubit(
                      context.read<ExpenseRepository>(),
                      context.read<BudgetRepository>(),
                    ),
                  ),
                  BlocProvider(
                    create: (_) => ExportCubit(context.read<ExportMonth>()),
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
    // TEMPORARY developer tool. Only exists in debug builds, so it can never
    // reach a release.
    if (kDebugMode)
      GoRoute(
        path: AppRoutes.ocrDebug,
        builder: (context, state) => const OcrDebugPage(),
      ),
    GoRoute(
      path: AppRoutes.categories,
      builder: (context, state) {
        final categories = context.read<CategoryRepository>();
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => CategoriesCubit(categories)),
            BlocProvider(create: (_) => _categoryActions(categories)),
          ],
          child: const CategoriesPage(),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.recurring,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => RecurringCubit(context.read<RecurringRepository>()),
          ),
          BlocProvider(
            create: (_) => CategoriesCubit(context.read<CategoryRepository>()),
          ),
        ],
        child: const RecurringPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.recurringForm,
      builder: (context, state) {
        final repository = context.read<RecurringRepository>();
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => RecurringFormCubit(
                saveRule: SaveRecurringRule(repository),
                repository: repository,
                generateDue: context.read<GenerateDueExpenses>(),
                original: state.extra as RecurringRule?,
              ),
            ),
            BlocProvider(
              create: (_) =>
                  CategoriesCubit(context.read<CategoryRepository>()),
            ),
          ],
          child: RecurringFormPage(original: state.extra as RecurringRule?),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.budgets,
      builder: (context, state) {
        final budgets = context.read<BudgetRepository>();
        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => BudgetsCubit(
                budgets,
                setBudget: SetBudget(budgets),
                removeBudget: RemoveBudget(budgets),
              ),
            ),
            BlocProvider(
              create: (_) =>
                  CategoriesCubit(context.read<CategoryRepository>()),
            ),
          ],
          child: const BudgetsPage(),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.scan,
      // The photo source arrives as `extra`; without it there is nothing to do.
      redirect: (context, state) =>
          state.extra is ReceiptSource ? null : AppRoutes.expenses,
      builder: (context, state) => BlocProvider(
        create: (_) => ScanCubit(
          ScanReceipt(
            photos: context.read<ReceiptPhotoSource>(),
            reader: context.read<ReceiptTextReader>(),
            categories: context.read<CategoryRepository>(),
            memory: context.read<VendorCategoryMemory>(),
          ),
        ),
        child: ScanPage(source: state.extra! as ReceiptSource),
      ),
    ),
    GoRoute(
      path: AppRoutes.addExpense,
      // After a scan, the result arrives as `extra` and fills in the form.
      builder: (context, state) => _expenseForm(
        context,
        scan: state.extra is ScanResult ? state.extra! as ScanResult : null,
      ),
    ),
    GoRoute(
      path: AppRoutes.editExpense,
      // The expense arrives as `extra`; without it there is nothing to edit.
      redirect: (context, state) =>
          state.extra is Expense ? null : AppRoutes.expenses,
      builder: (context, state) =>
          _expenseForm(context, original: state.extra! as Expense),
    ),
  ],
);

CategoryActionsCubit _categoryActions(CategoryRepository categories) =>
    CategoryActionsCubit(
      createCategory: CreateCategory(categories),
      findOrCreateCategory: FindOrCreateCategory(categories),
      renameCategory: RenameCategory(categories),
      deleteCategory: DeleteCategory(categories),
      repository: categories,
    );

/// The expense form: adding when [original] is null, editing otherwise. A
/// [scan] fills in the fields and shows the receipt photo.
Widget _expenseForm(
  BuildContext context, {
  Expense? original,
  ScanResult? scan,
}) {
  final expenses = context.read<ExpenseRepository>();
  final categories = context.read<CategoryRepository>();
  return MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => ExpenseFormCubit(
          saveExpense: SaveExpense(expenses),
          updateExpense: UpdateExpense(expenses),
          repository: expenses,
          original: original,
        ),
      ),
      BlocProvider(create: (_) => CategoriesCubit(categories)),
      // For the "New" chip: add a category without leaving the form.
      BlocProvider(create: (_) => _categoryActions(categories)),
    ],
    child: ExpenseFormPage(
      original: original,
      scan: scan,
      // The receipt photo is only for comparing, so it goes when the form does.
      discardPhoto: scan == null
          ? null
          : context.read<ReceiptPhotoSource>().discard,
    ),
  );
}
