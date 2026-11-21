import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
import '../../domain/entities/expense_filter.dart';
import '../cubit/expense_list_cubit.dart';
import '../cubit/expense_list_state.dart';
import '../widgets/day_header.dart';
import '../widgets/expense_tile.dart';

/// The list of expenses. With a [filter] it is the page behind a Summary
/// total: the expenses in one category and month, with a way back.
class ExpenseListPage extends StatelessWidget {
  const ExpenseListPage({super.key, this.filter});

  final ExpenseFilter? filter;

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

  /// "Food" or "All spending", for the page behind a Summary row.
  String _title(BuildContext context, ExpenseFilter filter) {
    final id = filter.categoryId;
    if (id == null) return 'All spending';
    return context.select<CategoriesCubit, String>(
      (cubit) => switch (cubit.state) {
        CategoriesLoaded(:final categories) =>
          categories.where((c) => c.id == id).firstOrNull?.name ??
              'Uncategorized',
        _ => '',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = this.filter;
    final month = filter?.month == null
        ? null
        : DateFormat.yMMMM().format(filter!.month!);
    final title = filter == null ? 'Expenses' : _title(context, filter);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
          ExpenseListLoaded(:final expenses)
              when expenses.isEmpty && filter != null =>
            EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Nothing here',
              message: month == null
                  ? 'There are no expenses to show.'
                  : 'There are no expenses in $month.',
            ),
          ExpenseListLoaded(:final expenses) when expenses.isEmpty =>
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Add your first expense',
              message: 'Tap the button below to record what you spent.',
            ),
          ExpenseListLoaded(:final groups, :final expenses) => _ExpenseList(
            groups: groups,
            onDelete: (expense) => _delete(context, expense),
            summary: filter == null
                ? null
                : _FilterSummary(
                    month: month,
                    count: expenses.length,
                    totalMinor: expenses.fold(
                      0,
                      (sum, e) => sum + e.amountMinor,
                    ),
                  ),
          ),
        },
      ),
    );
  }
}

/// "November 2026 · 5 expenses · KSh 12,300" above a filtered list.
class _FilterSummary extends StatelessWidget {
  const _FilterSummary({
    required this.month,
    required this.count,
    required this.totalMinor,
  });

  final String? month;
  final int count;
  final int totalMinor;

  @override
  Widget build(BuildContext context) {
    final currency = context.select<SettingsCubit, Currency>(
      (cubit) => cubit.state.currency,
    );
    final parts = [
      ?month,
      '$count ${count == 1 ? 'expense' : 'expenses'}',
      currency.format(totalMinor),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(parts.join(' · '), style: context.text.titleSmall),
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({
    required this.groups,
    required this.onDelete,
    this.summary,
  });

  final List<ExpenseDayGroup> groups;
  final Future<bool> Function(Expense) onDelete;

  /// Shown above the first day, for a filtered list.
  final Widget? summary;

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
      ?summary,
      for (final group in groups) ...[group, ...group.expenses],
    ];

    return ListView.builder(
      padding: AppSpacing.screen.copyWith(top: AppSpacing.xs, bottom: 96),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is Widget) return item;
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
