import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/core/utils/currency.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:smart_expense_tracker/features/insights/domain/entities/insight_alert.dart';
import 'package:smart_expense_tracker/features/insights/domain/usecases/find_alerts.dart';
import 'package:smart_expense_tracker/features/insights/presentation/widgets/alerts_section.dart';

import '../../support/builders.dart';

void main() {
  const find = FindAlerts();
  // Saturday 21 November 2026.
  final today = DateTime(2026, 11, 21, 10);

  Expense bill(
    int amount,
    DateTime date, {
    String vendor = 'Netflix',
    String id = '',
  }) => buildExpense(
    id: id.isEmpty ? '$vendor${date.toIso8601String()}' : id,
    vendor: vendor,
    amountMinor: amount,
    date: date,
    categoryId: 'bills',
  );

  /// Three months at 1,200.00, then a different amount in November.
  List<Expense> netflix(int latest) => [
    bill(120000, DateTime(2026, 8, 12)),
    bill(120000, DateTime(2026, 9, 12)),
    bill(120000, DateTime(2026, 10, 12)),
    bill(latest, DateTime(2026, 11, 12)),
  ];

  List<InsightAlert> prices(List<Expense> expenses) => [
    for (final a in find(expenses, today))
      if (a.kind == AlertKind.priceChanged) a,
  ];

  group('a price change', () {
    test('is told when a steady monthly payment goes up', () {
      final result = prices(netflix(150000));

      expect(result, hasLength(1));
      expect(result.single.vendor, 'Netflix');
      expect(result.single.amountMinor, 150000);
      expect(result.single.usualMinor, 120000);
    });

    test('is told when it goes down too', () {
      final result = prices(netflix(90000));

      expect(result.single.amountMinor, 90000);
      expect(result.single.usualMinor, 120000);
    });

    test('is not told when the amount did not change', () {
      expect(prices(netflix(120000)), isEmpty);
    });

    test('is not told for a change that is too small', () {
      // 1,200.00 to 1,205.00: under the 10.00 floor.
      expect(prices(netflix(120500)), isEmpty);
      // 3,000.00 to 3,050.00: 50.00, but under 5 percent.
      expect(
        prices([
          bill(300000, DateTime(2026, 8, 3), vendor: 'Rent'),
          bill(300000, DateTime(2026, 9, 3), vendor: 'Rent'),
          bill(300000, DateTime(2026, 10, 3), vendor: 'Rent'),
          bill(305000, DateTime(2026, 11, 3), vendor: 'Rent'),
        ]),
        isEmpty,
      );
    });

    test('needs three steady months first', () {
      expect(
        prices([
          bill(120000, DateTime(2026, 9, 12)),
          bill(120000, DateTime(2026, 10, 12)),
          bill(150000, DateTime(2026, 11, 12)),
        ]),
        isEmpty,
      );
      expect(
        prices([
          bill(100000, DateTime(2026, 8, 12)),
          bill(120000, DateTime(2026, 9, 12)),
          bill(120000, DateTime(2026, 10, 12)),
          bill(150000, DateTime(2026, 11, 12)),
        ]),
        isEmpty,
      );
    });

    test('needs the months to follow each other', () {
      expect(
        prices([
          bill(120000, DateTime(2026, 6, 12)),
          bill(120000, DateTime(2026, 8, 12)),
          bill(120000, DateTime(2026, 9, 12)),
          bill(150000, DateTime(2026, 11, 12)),
        ]),
        isEmpty,
      );
    });

    test('is not told for a shop visited several times a month', () {
      expect(
        prices([
          bill(120000, DateTime(2026, 8, 2), vendor: 'Cafe', id: 'a'),
          bill(120000, DateTime(2026, 8, 20), vendor: 'Cafe', id: 'b'),
          bill(120000, DateTime(2026, 9, 12), vendor: 'Cafe', id: 'c'),
          bill(120000, DateTime(2026, 10, 12), vendor: 'Cafe', id: 'd'),
          bill(150000, DateTime(2026, 11, 12), vendor: 'Cafe', id: 'e'),
        ]),
        isEmpty,
      );
    });

    test('is old news once the new price is more than five weeks old', () {
      final old = [
        bill(120000, DateTime(2026, 5, 12)),
        bill(120000, DateTime(2026, 6, 12)),
        bill(120000, DateTime(2026, 7, 12)),
        bill(150000, DateTime(2026, 8, 12)),
      ];

      expect(prices(old), isEmpty);
    });

    test('ignores an unknown vendor and matches the name loosely', () {
      expect(
        prices(
          [for (final e in netflix(150000)) e]
              .map(
                (e) => buildExpense(
                  id: e.id,
                  vendor: 'Unknown',
                  amountMinor: e.amountMinor,
                  date: e.date,
                ),
              )
              .toList(),
        ),
        isEmpty,
      );

      final mixed = [
        bill(120000, DateTime(2026, 8, 12), vendor: 'NETFLIX'),
        bill(120000, DateTime(2026, 9, 12), vendor: ' netflix '),
        bill(120000, DateTime(2026, 10, 12), vendor: 'Netflix'),
        bill(150000, DateTime(2026, 11, 12), vendor: 'netflix'),
      ];
      expect(prices(mixed), hasLength(1));
    });

    test('keeps the same id for the same change', () {
      expect(
        prices(netflix(150000)).single.id,
        prices(netflix(150000)).single.id,
      );
    });
  });

  testWidgets('the card says which way the price went', (tester) async {
    Future<void> show(InsightAlert alert) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AlertsSection(
            alerts: [alert],
            categoryNames: const {'bills': 'Bills'},
            currency: Currency.kes,
            onDismiss: (_) {},
          ),
        ),
      ),
    );

    await show(
      const InsightAlert(
        id: 'price:netflix:2026-11',
        kind: AlertKind.priceChanged,
        categoryId: 'bills',
        amountMinor: 150000,
        vendor: 'Netflix',
        usualMinor: 120000,
      ),
    );
    expect(find2('Price change at Netflix'), findsOneWidget);
    expect(find2Containing('went up from'), findsOneWidget);

    await show(
      const InsightAlert(
        id: 'price:netflix:2026-11',
        kind: AlertKind.priceChanged,
        categoryId: 'bills',
        amountMinor: 90000,
        vendor: 'Netflix',
        usualMinor: 120000,
      ),
    );
    expect(find2Containing('went down from'), findsOneWidget);
  });
}

Finder find2(String text) => find.text(text);
Finder find2Containing(String text) => find.textContaining(text);
