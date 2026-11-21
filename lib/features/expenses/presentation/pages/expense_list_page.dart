import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/add_expense_flow.dart';
import '../../../../app/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/color_contrast.dart';
import '../../../../core/utils/currency.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/cubit/categories_state.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/expense_day_group.dart';
import '../../domain/entities/expense_filter.dart';
import '../cubit/expense_list_cubit.dart';
import '../cubit/expense_list_state.dart';
import '../widgets/day_header.dart';
import '../widgets/expense_filter_sheet.dart';
import '../widgets/expense_tile.dart';

/// The list of expenses. On its own it can be searched and filtered. With a
/// [filter] it is the page behind a Summary total: the expenses in one
/// category and month, fixed, with a way back.
class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({super.key, this.filter});

  final ExpenseFilter? filter;

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  final _search = TextEditingController();
  bool _searching = false;

  bool get _interactive => widget.filter == null;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

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

  Future<void> _openFilters(BuildContext context) async {
    final cubit = context.read<ExpenseListCubit>();
    final categories = switch (context.read<CategoriesCubit>().state) {
      CategoriesLoaded(:final categories) => categories,
      _ => const <Category>[],
    };
    final currency = context.read<SettingsCubit>().state.currency;

    final next = await showExpenseFilterSheet(
      context,
      current: cubit.filter,
      categories: categories,
      currency: currency,
    );
    if (next != null) cubit.setFilter(next);
  }

  void _closeSearch(BuildContext context) {
    _search.clear();
    setState(() => _searching = false);
    final cubit = context.read<ExpenseListCubit>();
    cubit.setFilter(cubit.filter.copyWith(query: ''));
  }

  void _clearEverything(BuildContext context) {
    _search.clear();
    setState(() => _searching = false);
    context.read<ExpenseListCubit>().setFilter(const ExpenseFilter());
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    final fixed = widget.filter;
    if (fixed != null) return AppBar(title: Text(_title(context, fixed)));

    final cubit = context.read<ExpenseListCubit>();
    final active = context.select<ExpenseListCubit, int>(
      (cubit) => cubit.filter.activeCount,
    );
    return AppBar(
      title: _searching
          ? TextField(
              controller: _search,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration.collapsed(
                hintText: 'Search vendor or title',
              ),
              onChanged: (text) =>
                  cubit.setFilter(cubit.filter.copyWith(query: text)),
            )
          : const Text('Expenses'),
      actions: [
        if (_searching)
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close search',
            onPressed: () => _closeSearch(context),
          )
        else
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => setState(() => _searching = true),
          ),
        IconButton(
          icon: Badge(
            isLabelVisible: active > 0,
            label: Text('$active'),
            child: const Icon(Icons.tune),
          ),
          tooltip: 'Filter',
          onPressed: () => _openFilters(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fixed = widget.filter;
    final month = fixed?.month == null
        ? null
        : DateFormat.yMMMM().format(fixed!.month!);

    return Scaffold(
      appBar: _appBar(context),
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
          ExpenseListLoaded(:final expenses) when expenses.isEmpty => _empty(
            context,
            state,
            month,
          ),
          ExpenseListLoaded(:final groups, :final expenses) => _ExpenseList(
            groups: groups,
            onDelete: (expense) => _delete(context, expense),
            summary: fixed != null
                ? _FilterSummary(
                    month: month,
                    count: expenses.length,
                    totalMinor: _total(expenses),
                  )
                : state.filter.isEmpty
                ? null
                : _ActiveFilters(
                    filter: state.filter,
                    shown: expenses.length,
                    of: state.totalCount,
                    totalMinor: _total(expenses),
                    onChanged: context.read<ExpenseListCubit>().setFilter,
                    onQueryCleared: () => _closeSearch(context),
                  ),
          ),
        },
      ),
    );
  }

  Widget _empty(BuildContext context, ExpenseListLoaded state, String? month) {
    // The Summary page for a category and month that has nothing in it.
    if (!_interactive) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Nothing here',
        message: month == null
            ? 'There are no expenses to show.'
            : 'There are no expenses in $month.',
      );
    }
    // Expenses exist, but none pass the search and filters.
    if (state.totalCount > 0) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No matches',
        message: 'No expense fits this search. Try other words, or clear it.',
        action: OutlinedButton(
          onPressed: () => _clearEverything(context),
          child: const Text('Clear search and filters'),
        ),
      );
    }
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'Add your first expense',
      message:
          'Scan a receipt, type it in one line, paste an M-Pesa message, or '
          'enter it by hand. Everything stays on your phone.',
      action: FilledButton.icon(
        onPressed: () => startAddExpense(context),
        icon: const Icon(Icons.add),
        label: const Text('Add an expense'),
      ),
    );
  }

  static int _total(List<Expense> expenses) =>
      expenses.fold(0, (sum, e) => sum + e.amountMinor);
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

/// What the list is narrowed by, as chips that can each be removed, with how
/// many expenses that leaves and what they add up to.
class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({
    required this.filter,
    required this.shown,
    required this.of,
    required this.totalMinor,
    required this.onChanged,
    required this.onQueryCleared,
  });

  final ExpenseFilter filter;
  final int shown;
  final int of;
  final int totalMinor;
  final ValueChanged<ExpenseFilter> onChanged;
  final VoidCallback onQueryCleared;

  @override
  Widget build(BuildContext context) {
    final currency = context.select<SettingsCubit, Currency>(
      (cubit) => cubit.state.currency,
    );
    final categoryName = context.select<CategoriesCubit, String?>(
      (cubit) => switch (cubit.state) {
        CategoriesLoaded(:final categories) =>
          categories.where((c) => c.id == filter.categoryId).firstOrNull?.name,
        _ => null,
      },
    );
    final format = DateFormat.yMMMd();

    final chips = <Widget>[
      if (filter.hasQuery)
        InputChip(
          label: Text('"${filter.query.trim()}"'),
          onDeleted: onQueryCleared,
          deleteButtonTooltipMessage: 'Remove search',
        ),
      if (filter.categoryId != null)
        InputChip(
          label: Text(categoryName ?? 'Category'),
          onDeleted: () => onChanged(filter.copyWith(clearCategory: true)),
          deleteButtonTooltipMessage: 'Remove category',
        ),
      if (filter.from != null && filter.to != null)
        InputChip(
          label: Text(
            '${format.format(filter.from!)} - ${format.format(filter.to!)}',
          ),
          onDeleted: () => onChanged(filter.copyWith(clearDates: true)),
          deleteButtonTooltipMessage: 'Remove dates',
        ),
      if (filter.minMinor != null || filter.maxMinor != null)
        InputChip(
          label: Text(_amountText(currency)),
          onDeleted: () => onChanged(filter.copyWith(clearAmount: true)),
          deleteButtonTooltipMessage: 'Remove amount',
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chips.isNotEmpty)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: chips,
            ),
          const Gap(AppSpacing.sm),
          Text(
            '$shown of $of ${of == 1 ? 'expense' : 'expenses'} · '
            '${currency.format(totalMinor)}',
            style: context.text.titleSmall,
          ),
        ],
      ),
    );
  }

  String _amountText(Currency currency) {
    final min = filter.minMinor;
    final max = filter.maxMinor;
    if (min != null && max != null) {
      return '${currency.format(min)} - ${currency.format(max)}';
    }
    return min != null
        ? 'From ${currency.format(min)}'
        : 'Up to ${currency.format(max!)}';
  }
}
