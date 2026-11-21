import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/core/utils/currency.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget_progress.dart';
import 'package:smart_expense_tracker/features/budgets/presentation/widgets/budget_progress_tile.dart';

void main() {
  Future<void> show(WidgetTester tester, {required int spent}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: BudgetProgressTile(
              name: 'Food',
              currency: Currency.kes,
              progress: BudgetProgress(
                budget: const Budget(scopeId: 'food', limitMinor: 100000),
                spentMinor: spent,
              ),
            ),
          ),
        ),
      );

  testWidgets('within the limit shows what is left and the percent', (
    tester,
  ) async {
    await show(tester, spent: 50000);

    expect(find.textContaining('left'), findsOneWidget);
    expect(find.text('50% used'), findsOneWidget);
  });

  testWidgets('past the limit shows how much over, and no percent', (
    tester,
  ) async {
    await show(tester, spent: 251000);

    expect(find.textContaining('over'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });
}
