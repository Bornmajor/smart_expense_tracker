import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:smart_expense_tracker/features/insights/domain/entities/insight_alert.dart';
import 'package:smart_expense_tracker/features/insights/domain/usecases/find_alerts.dart';

void main() {
  const find = FindAlerts();
  // Friday 20 November 2026.
  final today = DateTime(2026, 11, 20, 10);

  var counter = 0;
  Expense expense({
    required DateTime date,
    int amountMinor = 50000,
    String vendor = 'Naivas',
    String categoryId = 'food',
    String? recurringRuleId,
  }) => Expense(
    id: 'e${counter++}',
    vendor: vendor,
    amountMinor: amountMinor,
    date: date,
    categoryId: categoryId,
    createdAt: date,
    updatedAt: date,
    recurringRuleId: recurringRuleId,
  );

  List<AlertKind> kinds(List<Expense> expenses) => [
    for (final a in find(expenses, today)) a.kind,
  ];

  group('possible duplicates', () {
    test('flags the same amount at the same vendor a day apart', () {
      final result = find([
        expense(date: DateTime(2026, 11, 19)),
        expense(date: DateTime(2026, 11, 20)),
      ], today);

      expect(result.single.kind, AlertKind.possibleDuplicate);
      expect(result.single.vendor, 'Naivas');
      expect(result.single.amountMinor, 50000);
    });

    test('ignores the vendor in a different case or with spaces', () {
      expect(
        kinds([
          expense(date: DateTime(2026, 11, 20), vendor: 'Naivas'),
          expense(date: DateTime(2026, 11, 20), vendor: ' naivas '),
        ]),
        [AlertKind.possibleDuplicate],
      );
    });

    test('does not flag different amounts, vendors or days apart', () {
      expect(
        kinds([
          expense(date: DateTime(2026, 11, 20), amountMinor: 50000),
          expense(date: DateTime(2026, 11, 20), amountMinor: 50100),
          expense(date: DateTime(2026, 11, 20), vendor: 'Quickmart'),
          expense(date: DateTime(2026, 11, 17)),
        ]),
        isEmpty,
      );
    });

    test('does not flag bills that repeat on purpose', () {
      expect(
        kinds([
          expense(date: DateTime(2026, 11, 19), recurringRuleId: 'r1'),
          expense(date: DateTime(2026, 11, 20), recurringRuleId: 'r1'),
        ]),
        isEmpty,
      );
    });

    test('does not flag an unknown vendor', () {
      expect(
        kinds([
          expense(date: DateTime(2026, 11, 20), vendor: 'Unknown'),
          expense(date: DateTime(2026, 11, 20), vendor: 'Unknown'),
        ]),
        isEmpty,
      );
    });

    test('is old news after a week', () {
      expect(
        kinds([
          expense(date: DateTime(2026, 11, 8)),
          expense(date: DateTime(2026, 11, 9)),
        ]),
        isEmpty,
      );
    });

    test('keeps the same id for the same finding', () {
      final list = [
        expense(date: DateTime(2026, 11, 19)),
        expense(date: DateTime(2026, 11, 20)),
      ];

      expect(find(list, today).single.id, find(list, today).single.id);
    });
  });

  group('unusually large expenses', () {
    List<Expense> usual() => [
      for (var i = 1; i <= 5; i++)
        expense(date: DateTime(2026, 10, i * 3), amountMinor: 50000),
    ];

    test('flags one far above the usual in its category', () {
      final result = find([
        ...usual(),
        expense(date: DateTime(2026, 11, 19), amountMinor: 200000),
      ], today);

      expect(result.single.kind, AlertKind.unusuallyLarge);
      expect(result.single.amountMinor, 200000);
      expect(result.single.usualMinor, 50000);
    });

    test('does not flag one only a little above', () {
      expect(
        kinds([
          ...usual(),
          expense(date: DateTime(2026, 11, 19), amountMinor: 100000),
        ]),
        isEmpty,
      );
    });

    test('needs enough history to know what is usual', () {
      expect(
        kinds([
          ...usual().take(3),
          expense(date: DateTime(2026, 11, 19), amountMinor: 900000),
        ]),
        isEmpty,
      );
    });

    test('does not flag a small amount however unusual', () {
      final small = [
        for (var i = 1; i <= 5; i++)
          expense(date: DateTime(2026, 10, i * 3), amountMinor: 1000),
      ];

      expect(
        kinds([
          ...small,
          expense(date: DateTime(2026, 11, 19), amountMinor: 5000),
        ]),
        isEmpty,
      );
    });

    test('compares with the same category only', () {
      expect(
        kinds([
          ...usual(),
          expense(
            date: DateTime(2026, 11, 19),
            amountMinor: 200000,
            categoryId: 'other',
          ),
        ]),
        isEmpty,
      );
    });
  });

  group('a category above normal', () {
    List<Expense> months(List<int> totals) => [
      for (var i = 0; i < totals.length; i++)
        if (totals[i] > 0)
          expense(
            date: DateTime(2026, 10 - i, 10),
            amountMinor: totals[i],
            vendor: 'Shop $i',
          ),
    ];

    test('flags a category well above what a month usually costs', () {
      final result = find([
        ...months([100000, 100000, 100000]),
        expense(date: DateTime(2026, 11, 3), amountMinor: 200000),
      ], today);

      final alert = result.single;
      expect(alert.kind, AlertKind.categoryAboveNormal);
      expect(alert.amountMinor, 200000);
      expect(alert.usualMinor, 100000);
      expect(alert.id, 'cat:food:2026-11');
    });

    test('does not flag a category that is only a little higher', () {
      expect(
        kinds([
          ...months([100000, 100000, 100000]),
          expense(date: DateTime(2026, 11, 3), amountMinor: 130000),
        ]),
        isEmpty,
      );
    });

    test('needs two earlier months of habit', () {
      expect(
        kinds([
          ...months([100000, 0, 0]),
          expense(date: DateTime(2026, 11, 3), amountMinor: 500000),
        ]),
        isEmpty,
      );
    });

    test('does not flag a small difference in a small category', () {
      expect(
        kinds([
          ...months([1000, 1000, 1000]),
          expense(date: DateTime(2026, 11, 3), amountMinor: 5000),
        ]),
        isEmpty,
      );
    });
  });

  test('shows at most three alerts, duplicates first', () {
    final many = <Expense>[
      for (final vendor in ['A', 'B', 'C', 'D']) ...[
        expense(date: DateTime(2026, 11, 19), vendor: vendor),
        expense(date: DateTime(2026, 11, 20), vendor: vendor),
      ],
    ];

    final result = find(many, today);

    expect(result, hasLength(3));
    expect(result.every((a) => a.kind == AlertKind.possibleDuplicate), isTrue);
  });

  test('finds nothing in an empty list', () {
    expect(find(const [], today), isEmpty);
  });
}
