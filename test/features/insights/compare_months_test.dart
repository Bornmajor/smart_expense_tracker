import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/core/utils/currency.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:smart_expense_tracker/features/insights/domain/entities/month_comparison.dart';
import 'package:smart_expense_tracker/features/insights/domain/usecases/compare_months.dart';
import 'package:smart_expense_tracker/features/insights/presentation/comparison_messages.dart';
import 'package:smart_expense_tracker/features/insights/presentation/widgets/month_comparison_card.dart';

import '../../support/builders.dart';

void main() {
  const compare = CompareMonths();
  // Saturday 21 November 2026.
  final today = DateTime(2026, 11, 21, 10);

  Expense spend(
    int amount,
    DateTime date, {
    String category = 'food',
    String id = '',
  }) => buildExpense(
    id: id.isEmpty ? '${date.toIso8601String()}$amount$category' : id,
    amountMinor: amount,
    date: date,
    categoryId: category,
  );

  group('CompareMonths', () {
    test('compares up to the same day in each month', () {
      final result = compare([
        spend(100000, DateTime(2026, 11, 5)),
        spend(50000, DateTime(2026, 11, 21)),
        // After today's date: this month it has not happened yet.
        spend(900000, DateTime(2026, 11, 22)),
        spend(80000, DateTime(2026, 10, 5)),
        spend(40000, DateTime(2026, 10, 21)),
        // Later in October than the 21st: left out of the comparison.
        spend(700000, DateTime(2026, 10, 25)),
      ], today)!;

      expect(result.currentMinor, 150000);
      expect(result.previousMinor, 120000);
      expect(result.deltaMinor, 30000);
      expect(result.percent, 25);
    });

    test('is null when nothing was spent at this point last month', () {
      expect(compare([spend(100000, DateTime(2026, 11, 5))], today), isNull);
      expect(compare(const [], today), isNull);
    });

    test('names the category that changed most, up or down', () {
      final up = compare([
        spend(300000, DateTime(2026, 11, 3), category: 'food'),
        spend(50000, DateTime(2026, 11, 4), category: 'transport'),
        spend(100000, DateTime(2026, 10, 3), category: 'food'),
        spend(40000, DateTime(2026, 10, 4), category: 'transport'),
      ], today)!;
      expect(up.biggestChangeCategoryId, 'food');
      expect(up.biggestChangeMinor, 200000);

      final down = compare([
        spend(100000, DateTime(2026, 11, 3), category: 'food'),
        spend(500000, DateTime(2026, 10, 3), category: 'food'),
        spend(40000, DateTime(2026, 11, 4), category: 'transport'),
        spend(50000, DateTime(2026, 10, 4), category: 'transport'),
      ], today)!;
      expect(down.biggestChangeCategoryId, 'food');
      expect(down.biggestChangeMinor, -400000);
    });

    test('names none when no category moved enough', () {
      final result = compare([
        spend(100000, DateTime(2026, 11, 3)),
        spend(95000, DateTime(2026, 10, 3)),
      ], today)!;

      expect(result.biggestChangeCategoryId, isNull);
    });

    test('a category that is new this month counts as a change', () {
      final result = compare([
        spend(250000, DateTime(2026, 11, 3), category: 'shopping'),
        spend(100000, DateTime(2026, 10, 3), category: 'food'),
        spend(100000, DateTime(2026, 11, 4), category: 'food'),
      ], today)!;

      expect(result.biggestChangeCategoryId, 'shopping');
    });

    test('on the 31st it takes all of a 30 day month', () {
      final result = compare([
        spend(100000, DateTime(2026, 12, 31)),
        spend(100000, DateTime(2026, 11, 30)),
      ], DateTime(2026, 12, 31))!;

      expect(result.previousMinor, 100000);
    });

    test('in January it looks back to December of last year', () {
      final result = compare([
        spend(100000, DateTime(2027, 1, 5)),
        spend(200000, DateTime(2026, 12, 5)),
      ], DateTime(2027, 1, 20))!;

      expect(result.currentMinor, 100000);
      expect(result.previousMinor, 200000);
      expect(result.percent, -50);
    });
  });

  group('MonthComparison', () {
    test('within 2 percent counts as the same', () {
      expect(
        const MonthComparison(
          currentMinor: 10100,
          previousMinor: 10000,
        ).aboutTheSame,
        isTrue,
      );
      expect(
        const MonthComparison(
          currentMinor: 10300,
          previousMinor: 10000,
        ).aboutTheSame,
        isFalse,
      );
    });
  });

  group('the words', () {
    test('say more or less with the percent', () {
      final more = comparisonText(
        const MonthComparison(currentMinor: 125000, previousMinor: 100000),
        null,
        Currency.kes,
      );
      final less = comparisonText(
        const MonthComparison(currentMinor: 50000, previousMinor: 100000),
        null,
        Currency.kes,
      );

      expect(more.detail, '25% more than at this point last month');
      expect(less.detail, '50% less than at this point last month');
      expect(more.biggest, isNull);
    });

    test('name the biggest change and its direction', () {
      final text = comparisonText(
        const MonthComparison(
          currentMinor: 300000,
          previousMinor: 100000,
          biggestChangeCategoryId: 'food',
          biggestChangeMinor: 200000,
        ),
        'Food',
        Currency.kes,
      );

      expect(text.biggest, startsWith('Biggest change: Food, up '));
    });
  });

  group('MonthComparisonCard', () {
    Future<void> show(
      WidgetTester tester,
      MonthComparison comparison, {
      String? name,
    }) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MonthComparisonCard(
              comparison: comparison,
              currency: Currency.kes,
              biggestChangeName: name,
            ),
          ),
        ),
      ),
    );

    testWidgets('shows the amount so far, the change and the biggest one', (
      tester,
    ) async {
      await show(
        tester,
        const MonthComparison(
          currentMinor: 300000,
          previousMinor: 200000,
          biggestChangeCategoryId: 'food',
          biggestChangeMinor: 100000,
        ),
        name: 'Food',
      );

      expect(find.text('Compared with last month'), findsOneWidget);
      expect(find.textContaining('so far'), findsOneWidget);
      expect(find.textContaining('50% more'), findsOneWidget);
      expect(find.textContaining('Biggest change: Food, up'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('less spending shows the down arrow', (tester) async {
      await show(
        tester,
        const MonthComparison(currentMinor: 100000, previousMinor: 200000),
      );

      expect(find.byIcon(Icons.trending_down), findsOneWidget);
      expect(find.textContaining('Biggest change'), findsNothing);
    });

    testWidgets('about the same shows a flat arrow', (tester) async {
      await show(
        tester,
        const MonthComparison(currentMinor: 100500, previousMinor: 100000),
      );

      expect(find.byIcon(Icons.trending_flat), findsOneWidget);
      expect(find.textContaining('About the same'), findsOneWidget);
    });

    testWidgets('fits a narrow phone at large text', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await show(
        tester,
        const MonthComparison(
          currentMinor: 99999999,
          previousMinor: 1000,
          biggestChangeCategoryId: 'food',
          biggestChangeMinor: 99000000,
        ),
        name: 'Food and drink and a very long name',
      );

      expect(tester.takeException(), isNull);
    });
  });
}
