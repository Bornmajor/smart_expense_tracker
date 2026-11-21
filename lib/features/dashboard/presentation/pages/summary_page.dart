import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_routes.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/cubit/categories_state.dart';
import '../../../expenses/domain/entities/expense_filter.dart';
import '../../../export/presentation/cubit/export_cubit.dart';
import '../../../export/presentation/cubit/export_state.dart';
import '../../../export/presentation/export_messages.dart';
import '../../../export/presentation/widgets/export_sheet.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../cubit/summary_cubit.dart';
import '../cubit/summary_state.dart';
import '../widgets/budget_section.dart';
import '../../../insights/presentation/cubit/alerts_cubit.dart';
import '../../../insights/presentation/widgets/alerts_section.dart';
import '../../../insights/presentation/widgets/month_comparison_card.dart';
import '../../../safe_to_spend/presentation/widgets/safe_to_spend_card.dart';
import '../widgets/category_breakdown_tile.dart';
import '../widgets/month_switcher.dart';
import '../widgets/total_card.dart';

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExportCubit, ExportState>(
      listener: (context, state) {
        if (state case ExportFailed(:final failure, :final month)) {
          final message = exportFailureMessage(failure, month);
          // An empty month is not an error, so it gets the milder color.
          if (failure case ExportFailure(
            problem: ExportProblem.nothingToExport,
          )) {
            context.showWarning(message);
          } else {
            context.showError(message);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Summary'),
          actions: const [_ExportButton()],
        ),
        body: BlocBuilder<SummaryCubit, SummaryState>(
          builder: (context, state) => switch (state) {
            SummaryLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            SummaryError() => const EmptyState(
              icon: Icons.error_outline,
              title: 'Couldn\'t load your summary',
              message: 'Close the app and open it again.',
            ),
            SummaryLoaded() => _SummaryContent(state: state),
          },
        ),
      ),
    );
  }
}

/// Opens the export sheet for the month on screen. It is off while the month
/// has no expenses, and shows progress while a report is being made.
class _ExportButton extends StatelessWidget {
  const _ExportButton();

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<SummaryCubit>().state;
    final exporting = context.watch<ExportCubit>().state is ExportWorking;

    if (exporting) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            semanticsLabel: 'Making your report',
          ),
        ),
      );
    }

    final month = switch (summary) {
      SummaryLoaded(:final month, summary: final s) when s.count > 0 => month,
      _ => null,
    };
    return IconButton(
      icon: const Icon(Icons.ios_share),
      tooltip: 'Export this month',
      onPressed: month == null ? null : () => _choose(context, month),
    );
  }

  Future<void> _choose(BuildContext context, DateTime month) async {
    final format = await showExportSheet(context, month);
    if (format == null || !context.mounted) return;
    await context.read<ExportCubit>().export(month, format);
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.state});

  final SummaryLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SummaryCubit>();
    final summary = state.summary;

    // The expenses behind a row: one category in the month shown, or the whole
    // month when [categoryId] is null.
    // Each category's budget, so its card can show how much is left.
    final budgetFor = {
      for (final progress in state.budgets)
        if (!progress.budget.isOverall) progress.budget.scopeId: progress,
    };
    void openExpenses(String? categoryId) => context.push(
      AppRoutes.filteredExpenses,
      extra: ExpenseFilter(categoryId: categoryId, month: state.month),
    );
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

    return ListView(
      padding: AppSpacing.screen.copyWith(bottom: 96),
      children: [
        MonthSwitcher(
          month: state.month,
          onPrevious: cubit.previousMonth,
          onNext: state.canGoNext ? cubit.nextMonth : null,
        ),
        AlertsSection(
          alerts: context.watch<AlertsCubit>().state,
          categoryNames: names,
          currency: currency,
          onDismiss: context.read<AlertsCubit>().dismiss,
        ),
        const Gap(AppSpacing.md),
        TotalCard(
          totalMinor: summary.totalMinor,
          count: summary.count,
          currency: currency,
        ),
        if (state.safeToSpend != null) ...[
          const Gap(AppSpacing.md),
          SafeToSpendCard(safeToSpend: state.safeToSpend!, currency: currency),
        ],
        if (state.comparison != null) ...[
          const Gap(AppSpacing.md),
          MonthComparisonCard(
            comparison: state.comparison!,
            currency: currency,
            biggestChangeName: names[state.comparison!.biggestChangeCategoryId],
          ),
        ],
        const Gap(AppSpacing.xl),
        BudgetSection(
          progress: state.budgets,
          currency: currency,
          onOpen: openExpenses,
        ),
        const Gap(AppSpacing.xl),
        if (summary.count == 0)
          SizedBox(
            height: 300,
            child: EmptyState(
              icon: Icons.pie_chart_outline,
              title: 'No expenses in ${DateFormat.yMMMM().format(state.month)}',
              message: state.canGoNext
                  ? 'Nothing was recorded this month.'
                  : 'Add an expense and your spending by category, budgets '
                        'and what is safe to spend show up here.',
            ),
          )
        else ...[
          const SectionHeader('By category'),
          for (final category in summary.categories) ...[
            CategoryBreakdownTile(
              name: names[category.categoryId] ?? 'Uncategorized',
              totalMinor: category.totalMinor,
              share: category.share,
              currency: currency,
              onTap: () => openExpenses(category.categoryId),
              budget: budgetFor[category.categoryId],
            ),
            const Gap(AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}
