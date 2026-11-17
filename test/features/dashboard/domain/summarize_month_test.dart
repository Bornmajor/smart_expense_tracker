import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/dashboard/domain/entities/month_summary.dart';
import 'package:smart_expense_tracker/features/dashboard/domain/usecases/summarize_month.dart';

import '../../../support/builders.dart';

void main() {
  const summarize = SummarizeMonth();
  final november = DateTime(2026, 11);

  group('SummarizeMonth', () {
    test('returns zeros for a month without expenses', () {
      final summary = summarize([], november);

      expect(summary.totalMinor, 0);
      expect(summary.count, 0);
      expect(summary.categories, isEmpty);
    });

    test('totals the month and splits it by category, largest first', () {
      final summary = summarize([
        buildExpense(id: '1', amountMinor: 300, categoryId: 'transport'),
        buildExpense(id: '2', amountMinor: 1000, categoryId: 'food'),
        buildExpense(id: '3', amountMinor: 200, categoryId: 'food'),
      ], november);

      expect(summary.totalMinor, 1500);
      expect(summary.count, 3);
      expect(summary.categories, const [
        CategoryTotal(categoryId: 'food', totalMinor: 1200, share: 0.8),
        CategoryTotal(categoryId: 'transport', totalMinor: 300, share: 0.2),
      ]);
    });

    test('ignores expenses from other months and years', () {
      final summary = summarize([
        buildExpense(id: '1', amountMinor: 100, date: DateTime(2026, 11, 1)),
        buildExpense(id: '2', amountMinor: 900, date: DateTime(2026, 10, 31)),
        buildExpense(id: '3', amountMinor: 900, date: DateTime(2025, 11, 15)),
        buildExpense(id: '4', amountMinor: 900, date: DateTime(2026, 12, 1)),
      ], november);

      expect(summary.totalMinor, 100);
      expect(summary.count, 1);
    });

    test('orders equal amounts by category id so the result is stable', () {
      final summary = summarize([
        buildExpense(id: '1', amountMinor: 500, categoryId: 'shopping'),
        buildExpense(id: '2', amountMinor: 500, categoryId: 'bills'),
      ], november);

      expect(summary.categories.map((c) => c.categoryId), [
        'bills',
        'shopping',
      ]);
    });

    test('shares add up to one', () {
      final summary = summarize([
        buildExpense(id: '1', amountMinor: 333, categoryId: 'a'),
        buildExpense(id: '2', amountMinor: 333, categoryId: 'b'),
        buildExpense(id: '3', amountMinor: 334, categoryId: 'c'),
      ], november);

      final sum = summary.categories.fold<double>(0, (s, c) => s + c.share);
      expect(sum, closeTo(1, 1e-9));
    });
  });
}
