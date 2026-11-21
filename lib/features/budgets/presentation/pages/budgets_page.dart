import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/cubit/categories_state.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/budget.dart';
import '../cubit/budgets_cubit.dart';
import '../cubit/budgets_state.dart';
import '../edit_budget.dart';

/// Set the monthly limit for everything together, and for each category.
class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  Future<void> _edit(
    BuildContext context, {
    required String scopeId,
    required String title,
    required Budget? existing,
    required Currency currency,
  }) => editBudget(
    context,
    cubit: context.read<BudgetsCubit>(),
    scopeId: scopeId,
    title: title,
    existing: existing,
    currency: currency,
  );

  @override
  Widget build(BuildContext context) {
    final currency = context.select<SettingsCubit, Currency>(
      (cubit) => cubit.state.currency,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: BlocBuilder<BudgetsCubit, BudgetsState>(
        builder: (context, budgetsState) =>
            BlocBuilder<CategoriesCubit, CategoriesState>(
              builder: (context, categoriesState) {
                if (budgetsState is BudgetsError ||
                    categoriesState is CategoriesError) {
                  return const EmptyState(
                    icon: Icons.error_outline,
                    title: 'Couldn\'t load your budgets',
                    message: 'Close the app and open it again.',
                  );
                }
                if (budgetsState is! BudgetsLoaded ||
                    categoriesState is! CategoriesLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                final budgets = budgetsState.byScope;
                return ListView(
                  padding: AppSpacing.screen.copyWith(bottom: 96),
                  children: [
                    Text(
                      'A budget is how much you plan to spend each month. '
                      'It applies to every month, and the Summary shows how '
                      'much of it you have used.',
                      style: context.text.bodyMedium,
                    ),
                    const Gap(AppSpacing.lg),
                    const SectionHeader('Overall'),
                    _BudgetTile(
                      icon: Icons.savings_outlined,
                      name: 'All spending',
                      budget: budgets[Budget.overallId],
                      currency: currency,
                      onTap: () => _edit(
                        context,
                        scopeId: Budget.overallId,
                        title: 'Overall budget',
                        existing: budgets[Budget.overallId],
                        currency: currency,
                      ),
                    ),
                    const Gap(AppSpacing.xl),
                    const SectionHeader('By category'),
                    for (final category in categoriesState.categories) ...[
                      _BudgetTile(
                        name: category.name,
                        budget: budgets[category.id],
                        currency: currency,
                        onTap: () => _edit(
                          context,
                          scopeId: category.id,
                          title: '${category.name} budget',
                          existing: budgets[category.id],
                          currency: currency,
                        ),
                      ),
                      const Gap(AppSpacing.sm),
                    ],
                  ],
                );
              },
            ),
      ),
    );
  }
}

class _BudgetTile extends StatelessWidget {
  const _BudgetTile({
    required this.name,
    required this.budget,
    required this.currency,
    required this.onTap,
    this.icon,
  });

  final String name;
  final Budget? budget;
  final Currency currency;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final limit = budget?.limitMinor;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: icon == null ? null : Icon(icon),
        title: Text(name),
        subtitle: Text(
          limit == null ? 'No limit' : '${currency.format(limit)} a month',
          style: context.text.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
