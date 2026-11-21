import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:smart_expense_tracker/core/utils/currency.dart';
import 'package:smart_expense_tracker/features/categories/domain/entities/category.dart';
import 'package:smart_expense_tracker/features/export/domain/entities/monthly_report.dart';
import 'package:smart_expense_tracker/features/export/domain/usecases/build_monthly_report.dart';

import '../../../support/builders.dart';

void main() {
  const buildReport = BuildMonthlyReport();
  MonthlyReport build(
    List<Expense> expenses,
    List<Category> categories,
    DateTime month,
  ) => buildReport(expenses, categories, month, currency: Currency.none);
  const categories = [
    Category(id: 'food', name: 'Food'),
    Category(id: 'transport', name: 'Transport'),
  ];
  final november = DateTime(2026, 11);

  test('keeps only the chosen month', () {
    final report = build(
      [
        buildExpense(id: 'a', date: DateTime(2026, 10, 31)),
        buildExpense(id: 'b', date: DateTime(2026, 11, 1)),
        buildExpense(id: 'c', date: DateTime(2026, 11, 30)),
        buildExpense(id: 'd', date: DateTime(2026, 12, 1)),
        buildExpense(id: 'e', date: DateTime(2025, 11, 15)),
      ],
      categories,
      november,
    );

    expect(report.rows, hasLength(2));
    expect(report.rows.map((r) => r.date.day), [1, 30]);
  });

  test('lists the oldest expense first', () {
    final report = build(
      [
        buildExpense(id: 'late', date: DateTime(2026, 11, 20)),
        buildExpense(id: 'early', date: DateTime(2026, 11, 2)),
        buildExpense(id: 'mid', date: DateTime(2026, 11, 10)),
      ],
      categories,
      november,
    );

    expect(report.rows.map((r) => r.date.day), [2, 10, 20]);
  });

  test('keeps entry order for expenses on the same day', () {
    final day = DateTime(2026, 11, 5);
    final first = buildExpense(id: 'first', vendor: 'First', date: day);
    final second = buildExpense(
      id: 'second',
      vendor: 'Second',
      date: day,
      createdAt: day.add(const Duration(hours: 3)),
    );

    // The list comes newest first, as from the repository.
    final report = build([second, first], categories, november);

    expect(report.rows.map((r) => r.vendor), ['First', 'Second']);
  });

  test('puts the category name on each row', () {
    final report = build(
      [
        buildExpense(categoryId: 'food', title: 'Lunch', vendor: 'Cafe'),
        buildExpense(id: 'b', categoryId: 'transport', vendor: 'Bus'),
      ],
      categories,
      november,
    );

    expect(report.rows.first.categoryName, 'Food');
    expect(report.rows.first.title, 'Lunch');
    expect(report.rows.last.categoryName, 'Transport');
  });

  test('labels an unknown category instead of failing', () {
    final report = build(
      [buildExpense(categoryId: 'deleted')],
      categories,
      november,
    );

    expect(report.rows.single.categoryName, 'Uncategorized');
    expect(report.categories.single.name, 'Uncategorized');
  });

  test('totals the month and each category, largest first', () {
    final report = build(
      [
        buildExpense(id: 'a', amountMinor: 1000, categoryId: 'food'),
        buildExpense(id: 'b', amountMinor: 3000, categoryId: 'transport'),
        buildExpense(id: 'c', amountMinor: 1000, categoryId: 'food'),
      ],
      categories,
      november,
    );

    expect(report.totalMinor, 5000);
    expect(report.categories, [
      const ReportCategory(name: 'Transport', totalMinor: 3000, share: 0.6),
      const ReportCategory(name: 'Food', totalMinor: 2000, share: 0.4),
    ]);
  });

  test('matches the Summary screen total', () {
    final expenses = [
      buildExpense(id: 'a', amountMinor: 1234),
      buildExpense(id: 'b', amountMinor: 99, date: DateTime(2026, 11, 3)),
      buildExpense(id: 'c', amountMinor: 5000, date: DateTime(2026, 10, 3)),
    ];

    final report = build(expenses, categories, november);

    expect(report.totalMinor, 1333);
  });

  test('an empty month gives an empty report', () {
    final report = build(const [], categories, november);

    expect(report.rows, isEmpty);
    expect(report.categories, isEmpty);
    expect(report.totalMinor, 0);
  });

  test('accepts any day of the month and stores its first day', () {
    final report = build(
      [buildExpense(date: DateTime(2026, 11, 16))],
      categories,
      DateTime(2026, 11, 28),
    );

    expect(report.month, DateTime(2026, 11));
    expect(report.rows, hasLength(1));
  });

  group('file name', () {
    test('has the year, a two-digit month and the extension', () {
      final report = build(const [], categories, DateTime(2026, 3));

      expect(report.fileName('pdf'), 'spendwise-iq-2026-03.pdf');
      expect(report.fileName('csv'), 'spendwise-iq-2026-03.csv');
    });
  });
}
