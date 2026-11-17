import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/app/app_router.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:smart_expense_tracker/features/expenses/domain/repositories/expense_repository.dart';

import '../support/fakes.dart';

void main() {
  late FakeExpenseRepository expenses;

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ExpenseRepository>.value(value: expenses),
          RepositoryProvider<CategoryRepository>.value(
            value: FakeCategoryRepository(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: createRouter(
            onboarding: FakeOnboardingRepository(completed: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openAddExpense(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.text('Save expense'));
    await tester.pumpAndSettle();
  }

  setUp(() => expenses = FakeExpenseRepository());

  testWidgets('adds an expense and shows it in the list', (tester) async {
    await pumpApp(tester);
    expect(find.text('Add your first expense'), findsOneWidget);

    await openAddExpense(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '12.50');
    await tester.tap(find.text('Food'));
    await tester.pump();
    await tapSave(tester);

    expect(find.text('Expense saved'), findsOneWidget);
    expect(find.text('Add your first expense'), findsNothing);
    expect(find.text('Unknown'), findsOneWidget);
    expect(find.text('12.50'), findsOneWidget);
    expect(expenses.saved.single.categoryId, 'food');
  });

  testWidgets('shows validation messages and stays on the form', (
    tester,
  ) async {
    await pumpApp(tester);

    await openAddExpense(tester);
    await tapSave(tester);

    expect(find.text('Enter an amount'), findsOneWidget);
    expect(find.text('Choose a category'), findsOneWidget);
    expect(find.text('Save expense'), findsOneWidget);
    expect(expenses.saved, isEmpty);
  });

  testWidgets('tells the user when saving fails', (tester) async {
    expenses.saveError = const StorageException('disk full');
    await pumpApp(tester);

    await openAddExpense(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '5');
    await tester.tap(find.text('Transport'));
    await tester.pump();
    await tapSave(tester);

    expect(find.text('Couldn\'t save the expense. Try again.'), findsOneWidget);
  });
}
