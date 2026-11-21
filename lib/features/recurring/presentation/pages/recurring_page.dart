import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../../shared/widgets/amount_row.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/cubit/categories_state.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/recurring_rule.dart';
import '../cubit/recurring_cubit.dart';
import '../cubit/recurring_state.dart';

/// Rent, subscriptions and bills that repeat. When a date comes due, an
/// expense is added on its own.
class RecurringPage extends StatelessWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currency = context.select<SettingsCubit, Currency>(
      (cubit) => cubit.state.currency,
    );
    final names = context.select<CategoriesCubit, Map<String, String>>(
      (cubit) => switch (cubit.state) {
        CategoriesLoaded(:final categories) => {
          for (final c in categories) c.id: c.name,
        },
        _ => const {},
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Recurring expenses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.recurringForm),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: BlocBuilder<RecurringCubit, RecurringState>(
        builder: (context, state) => switch (state) {
          RecurringLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          RecurringLoadFailed() => const EmptyState(
            icon: Icons.error_outline,
            title: 'Couldn\'t load your recurring expenses',
            message: 'Close the app and open it again.',
          ),
          RecurringLoaded(:final rules) when rules.isEmpty => EmptyState(
            icon: Icons.repeat,
            title: 'Nothing repeats yet',
            message:
                'Add rent, a subscription or a bill, and it is added to your '
                'expenses on its own each time it comes around.',
            action: FilledButton.icon(
              onPressed: () => context.push(AppRoutes.recurringForm),
              icon: const Icon(Icons.add),
              label: const Text('Add a recurring expense'),
            ),
          ),
          RecurringLoaded() => _RuleList(
            state: state,
            currency: currency,
            categoryNames: names,
          ),
        },
      ),
    );
  }
}

class _RuleList extends StatelessWidget {
  const _RuleList({
    required this.state,
    required this.currency,
    required this.categoryNames,
  });

  final RecurringLoaded state;
  final Currency currency;
  final Map<String, String> categoryNames;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.screen.copyWith(bottom: 96),
      children: [
        Text(
          'About ${currency.format(state.monthlyCostMinor)} a month',
          style: context.text.titleMedium,
        ),
        const Gap(AppSpacing.xs),
        Text(
          'What your active recurring expenses add up to. Weekly and yearly '
          'ones are spread over a month.',
          style: context.text.bodySmall,
        ),
        const Gap(AppSpacing.lg),
        for (final rule in state.rules) ...[
          _RuleTile(
            rule: rule,
            currency: currency,
            categoryName: categoryNames[rule.categoryId],
          ),
          const Gap(AppSpacing.sm),
        ],
      ],
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.rule,
    required this.currency,
    required this.categoryName,
  });

  final RecurringRule rule;
  final Currency currency;
  final String? categoryName;

  String get _details => [
    rule.frequency.label,
    rule.isActive ? 'Next ${DateFormat.MMMd().format(rule.nextDue)}' : 'Paused',
    ?categoryName,
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.recurringForm, extra: rule),
        child: Padding(
          padding: AppSpacing.card,
          child: Opacity(
            opacity: rule.isActive ? 1 : 0.6,
            child: AmountRow(
              leading: Row(
                children: [
                  Icon(
                    rule.isActive ? Icons.repeat : Icons.pause_circle_outline,
                    size: 20,
                    color: context.scheme.onSurfaceVariant,
                  ),
                  const Gap(AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rule.displayName, style: context.text.titleMedium),
                        const Gap(AppSpacing.xs),
                        Text(_details, style: context.text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              amount: currency.format(rule.amountMinor),
              amountStyle: context.text.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}
