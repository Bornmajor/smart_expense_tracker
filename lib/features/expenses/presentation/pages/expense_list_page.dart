import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/color_contrast.dart';
import '../../../../core/utils/currency.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/cubit/categories_state.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_day_group.dart';
import '../cubit/expense_list_cubit.dart';
import '../cubit/expense_list_state.dart';
import '../widgets/day_header.dart';
import '../widgets/expense_tile.dart';

class ExpenseListPage extends StatelessWidget {
  const ExpenseListPage({super.key});

  /// Returns whether the expense was deleted, so a swiped row knows whether
  /// to leave or spring back.
  Future<bool> _delete(BuildContext context, Expense expense) async {
    final cubit = context.read<ExpenseListCubit>();
    final deleted = await cubit.delete(expense);
    if (!context.mounted) return deleted;

    if (deleted) {
      context.showInfo(
        'Expense deleted',
        actionLabel: 'Undo',
        onAction: () async {
          final restored = await cubit.restore(expense);
          if (!context.mounted || restored) return;
          context.showError('Couldn\'t restore the expense.');
        },
      );
    } else {
      context.showError('Couldn\'t delete the expense. Try again.');
    }
    return deleted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: BlocBuilder<ExpenseListCubit, ExpenseListState>(
        builder: (context, state) => switch (state) {
          ExpenseListLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          ExpenseListError() => const EmptyState(
            icon: Icons.error_outline,
            title: 'Couldn\'t load expenses',
            message: 'Close the app and open it again.',
          ),
          ExpenseListLoaded(:final expenses) when expenses.isEmpty =>
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Add your first expense',
              message: 'Tap the button below to record what you spent.',
            ),
          ExpenseListLoaded(:final groups) => _ExpenseList(
            groups: groups,
            onDelete: (expense) => _delete(context, expense),
          ),
        },
      ),
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.groups, required this.onDelete});

  final List<ExpenseDayGroup> groups;
  final Future<bool> Function(Expense) onDelete;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currency = context.select<SettingsCubit, Currency>(
      (cubit) => cubit.state.currency,
    );
    final categoryNames = context.select<CategoriesCubit, Map<String, String>>(
      (cubit) => switch (cubit.state) {
        CategoriesLoaded(:final categories) => {
          for (final c in categories) c.id: c.name,
        },
        _ => const {},
      },
    );

    // Day headers and expenses in one flat list, so the list builds lazily.
    final items = <Object>[
      for (final group in groups) ...[group, ...group.expenses],
    ];

    return ListView.builder(
      padding: AppSpacing.screen.copyWith(top: AppSpacing.xs, bottom: 96),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is ExpenseDayGroup) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: DayHeader(group: item, now: now, currency: currency),
          );
        }

        final expense = item as Expense;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _SwipeToDelete(
            key: ValueKey(expense.id),
            onDelete: () => onDelete(expense),
            child: ExpenseTile(
              expense: expense,
              currency: currency,
              categoryName: categoryNames[expense.categoryId],
              onTap: () => context.push(AppRoutes.editExpense, extra: expense),
            ),
          ),
        );
      },
    );
  }
}

/// Swipe a row to the left to delete it. The delete runs first: when it
/// succeeds the row goes (the list drops it), and when it fails the row
/// springs back to where it was.
class _SwipeToDelete extends StatelessWidget {
  const _SwipeToDelete({
    super.key,
    required this.child,
    required this.onDelete,
  });

  final Widget child;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final danger = context.semantic.danger;
    return Dismissible(
      key: key!,
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete(),
      background: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: ColoredBox(
          color: danger,
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xl),
              child: Icon(Icons.delete_outline, color: readableOn(danger)),
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}
