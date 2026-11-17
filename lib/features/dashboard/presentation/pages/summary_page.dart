import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/cubit/categories_state.dart';
import '../cubit/summary_cubit.dart';
import '../cubit/summary_state.dart';
import '../widgets/category_breakdown_tile.dart';
import '../widgets/month_switcher.dart';
import '../widgets/total_card.dart';

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: BlocBuilder<SummaryCubit, SummaryState>(
        builder: (context, state) => switch (state) {
          SummaryLoading() => const Center(child: CircularProgressIndicator()),
          SummaryError() => const EmptyState(
            icon: Icons.error_outline,
            title: 'Couldn\'t load your summary',
            message: 'Close the app and open it again.',
          ),
          SummaryLoaded() => _SummaryContent(state: state),
        },
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.state});

  final SummaryLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SummaryCubit>();
    final summary = state.summary;
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
        const Gap(AppSpacing.md),
        TotalCard(totalMinor: summary.totalMinor, count: summary.count),
        const Gap(AppSpacing.xl),
        if (summary.count == 0)
          SizedBox(
            height: 240,
            child: EmptyState(
              icon: Icons.pie_chart_outline,
              title: 'No expenses in ${DateFormat.yMMMM().format(state.month)}',
              message: 'Expenses you add will show up here.',
            ),
          )
        else ...[
          const SectionHeader('By category'),
          for (final category in summary.categories) ...[
            CategoryBreakdownTile(
              name: names[category.categoryId] ?? 'Uncategorized',
              totalMinor: category.totalMinor,
              share: category.share,
            ),
            const Gap(AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}
