import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../cubit/expense_list_cubit.dart';
import '../cubit/expense_list_state.dart';
import '../widgets/expense_tile.dart';

class ExpenseListPage extends StatelessWidget {
  const ExpenseListPage({super.key});

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
          ExpenseListLoaded(:final expenses) => ListView.separated(
            padding: AppSpacing.screen.copyWith(top: AppSpacing.sm, bottom: 96),
            itemCount: expenses.length,
            separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
            itemBuilder: (_, index) => ExpenseTile(expense: expenses[index]),
          ),
        },
      ),
    );
  }
}
