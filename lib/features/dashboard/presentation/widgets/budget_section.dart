import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../budgets/domain/entities/budget_progress.dart';
import '../../../budgets/presentation/widgets/budget_progress_tile.dart';

/// The overall budget on the Summary: how much of it this month has used, and
/// what is left. Each category's own budget shows on that category's card, so it
/// is not listed again here. With no overall budget it offers to set one, and
/// Edit opens the screen with every budget.
class BudgetSection extends StatelessWidget {
  const BudgetSection({
    super.key,
    required this.progress,
    required this.currency,
    this.onOpen,
  });

  final List<BudgetProgress> progress;

  /// Opens the expenses behind a budget: the category id, or null for the
  /// overall budget (the whole month).
  final void Function(String? categoryId)? onOpen;

  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final overall = progress.where((p) => p.budget.isOverall).firstOrNull;
    if (overall == null) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: const Icon(Icons.savings_outlined),
          title: const Text('Set a monthly budget'),
          subtitle: const Text('See how much you have left to spend'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.budgets),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Budgets', style: context.text.titleMedium),
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.budgets),
              child: const Text('Edit'),
            ),
          ],
        ),
        const Gap(AppSpacing.xs),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: BudgetProgressTile(
            name: 'All spending',
            progress: overall,
            currency: currency,
            onTap: onOpen == null ? null : () => onOpen!(null),
          ),
        ),
      ],
    );
  }
}
