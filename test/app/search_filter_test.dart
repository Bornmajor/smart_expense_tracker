import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';
import '../support/fakes.dart';
import '../support/pump_app.dart';

/// Finding expenses on the main list: search words, then the filter sheet.
void main() {
  final today = DateTime.now();

  late FakeExpenseRepository expenses;

  setUp(() {
    expenses = FakeExpenseRepository(
      initial: [
        buildExpense(
          id: 'a',
          vendor: 'Naivas',
          amountMinor: 250000,
          categoryId: 'food',
          date: today,
        ),
        buildExpense(
          id: 'b',
          vendor: 'Java House',
          amountMinor: 80000,
          categoryId: 'food',
          date: today,
        ),
        buildExpense(
          id: 'c',
          vendor: 'Uber',
          amountMinor: 120000,
          categoryId: 'transport',
          date: today,
        ),
      ],
    );
  });

  Future<void> open(WidgetTester tester) =>
      pumpRouterApp(tester, expenses: expenses);

  Future<void> search(WidgetTester tester, String text) async {
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
  }

  testWidgets('searching shows only matching expenses', (tester) async {
    await open(tester);

    await search(tester, 'naiv');

    expect(find.text('Naivas'), findsOneWidget);
    expect(find.text('Uber'), findsNothing);
    expect(find.textContaining('1 of 3 expenses'), findsOneWidget);
  });

  testWidgets('removing the search chip brings everything back', (
    tester,
  ) async {
    await open(tester);
    await search(tester, 'naiv');

    await tester.tap(find.byTooltip('Remove search'));
    await tester.pumpAndSettle();

    expect(find.text('Uber'), findsOneWidget);
    expect(find.text('Naivas'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('no match says so, and one tap clears it', (tester) async {
    await open(tester);

    await search(tester, 'zzz');

    expect(find.text('No matches'), findsOneWidget);
    expect(find.text('Add your first expense'), findsNothing);

    await tester.tap(find.text('Clear search and filters'));
    await tester.pumpAndSettle();

    expect(find.text('Naivas'), findsOneWidget);
    expect(find.text('Uber'), findsOneWidget);
  });

  testWidgets('the filter sheet narrows by category and amount', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Food'));
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'Lowest'), '1000');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Naivas'), findsOneWidget);
    expect(find.text('Java House'), findsNothing);
    expect(find.text('Uber'), findsNothing);
    expect(find.textContaining('1 of 3 expenses'), findsOneWidget);
  });

  testWidgets('the filter button shows how many filters are on', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Food'));
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(Badge, '1'), findsOneWidget);
  });

  testWidgets('a lowest amount above the highest is not accepted', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Lowest'), '900');
    await tester.enterText(find.widgetWithText(TextField, 'Highest'), '100');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.textContaining('lowest can\'t be above'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget, reason: 'the sheet stays open');
  });

  testWidgets('removing a filter chip widens the list again', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Transport'));
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('Naivas'), findsNothing);

    await tester.tap(find.byTooltip('Remove category'));
    await tester.pumpAndSettle();

    expect(find.text('Naivas'), findsOneWidget);
  });

  testWidgets('an empty app still asks for the first expense', (tester) async {
    expenses = FakeExpenseRepository();
    await open(tester);

    expect(find.text('Add your first expense'), findsOneWidget);
    expect(find.text('No matches'), findsNothing);
  });
}
