import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/cubit/categories_state.dart';
import '../../../expenses/domain/entities/expense_filter.dart';
import '../../../insights/presentation/cubit/alerts_cubit.dart';
import '../../../insights/presentation/widgets/alerts_section.dart';
import '../../../insights/presentation/widgets/month_comparison_card.dart';
import '../../../profile/presentation/cubit/profile_cubit.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/greeting_header.dart';
import '../widgets/money_card.dart';
import '../widgets/recent_expenses.dart';
import '../widgets/year_chart.dart';

/// The first screen: a greeting, how this month is going, the year at a glance,
/// the latest expenses and anything worth a second look. The full list and the
/// detail are one tap away on the other tabs.
class HomePage extends StatelessWidget {
  const HomePage({super.key, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) => switch (state) {
            HomeLoading() => const Center(child: CircularProgressIndicator()),
            HomeError() => const EmptyState(
              icon: Icons.error_outline,
              title: 'Couldn\'t load your expenses',
              message: 'Close the app and open it again.',
            ),
            HomeLoaded() => _Loaded(state: state, now: _now()),
          },
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state, required this.now});

  final HomeLoaded state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final currency = context.select<SettingsCubit, Currency>(
      (cubit) => cubit.state.currency,
    );
    final name = context.watch<ProfileCubit>().state;
    final names = context.select<CategoriesCubit, Map<String, String>>(
      (cubit) => switch (cubit.state) {
        CategoriesLoaded(:final categories) => {
          for (final c in categories) c.id: c.name,
        },
        _ => const {},
      },
    );
    final alerts = context.watch<AlertsCubit>().state;
    final shell = StatefulNavigationShell.of(context);

    return ListView(
      padding: AppSpacing.screen.copyWith(top: AppSpacing.lg, bottom: 96),
      children: [
        GreetingHeader(name: name, now: now),
        const Gap(AppSpacing.lg),
        if (!state.hasExpenses)
          const _Welcome()
        else ...[
          MoneyCard(
            spentMinor: state.spentThisMonth,
            currency: currency,
            budget: state.overallBudget,
            safeToSpend: state.safeToSpend,
            onOpen: () => shell.goBranch(AppTabs.summary),
            onSetBudget: () => context.push(AppRoutes.budgets),
          ),
          if (state.comparison != null) ...[
            const Gap(AppSpacing.lg),
            MonthComparisonCard(
              comparison: state.comparison!,
              currency: currency,
              biggestChangeName:
                  names[state.comparison!.biggestChangeCategoryId],
            ),
          ],
          const Gap(AppSpacing.lg),
          // Only the most pressing, so the screen stays calm. All of them are
          // on the Summary.
          AlertsSection(
            alerts: alerts.take(2).toList(),
            categoryNames: names,
            currency: currency,
            onDismiss: context.read<AlertsCubit>().dismiss,
          ),
          YearChart(
            year: state.year,
            totals: state.monthlyTotals,
            currentMonth: state.month,
            budgetMinor: state.overallBudget?.limitMinor,
            currency: currency,
            onMonthTap: (month) => context.push(
              AppRoutes.filteredExpenses,
              extra: ExpenseFilter(month: DateTime(state.year, month)),
            ),
          ),
          const Gap(AppSpacing.lg),
          RecentExpenses(
            expenses: state.recent,
            categoryNames: names,
            currency: currency,
            onOpen: (expense) =>
                context.push(AppRoutes.editExpense, extra: expense),
            onSeeAll: () => shell.goBranch(AppTabs.expenses),
          ),
        ],
      ],
    );
  }
}

/// What a brand new app shows in place of the numbers.
class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.waving_hand_outlined, color: context.scheme.primary),
            const Gap(AppSpacing.md),
            Text(
              'Let\'s add your first expense',
              style: context.text.titleMedium,
            ),
            const Gap(AppSpacing.sm),
            Text(
              'Adding an expense is effortless: scan a receipt, type it in one '
              'line, or paste an M-Pesa message.',
              style: context.text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
