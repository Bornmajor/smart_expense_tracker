import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../budgets/domain/entities/budget_progress.dart';
import '../../../budgets/presentation/widgets/budget_progress_tile.dart';

/// The budgets on the Summary: how much of each limit this month has used. With
/// no budget set it offers to set one.
class BudgetSection extends StatelessWidget {
  const BudgetSection({
    super.key,
    required this.progress,
    required this.categoryNames,
    required this.currency,
    this.onOpen,
  });

  final List<BudgetProgress> progress;

  /// Opens the expenses behind a budget: the category id, or null for the
  /// overall budget (the whole month).
  final void Function(String? categoryId)? onOpen;

  /// Category id -> name. A budget whose category is not in here is left out.
  final Map<String, String> categoryNames;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    if (progress.isEmpty) {
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
        for (final item in progress)
          if (item.budget.isOverall ||
              categoryNames[item.budget.scopeId] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: BudgetProgressTile(
                name: item.budget.isOverall
                    ? 'All spending'
                    : categoryNames[item.budget.scopeId]!,
                progress: item,
                currency: currency,
                onTap: onOpen == null
                    ? null
                    : () => onOpen!(
                        item.budget.isOverall ? null : item.budget.scopeId,
                      ),
              ),
            ),
      ],
    );
  }
}
