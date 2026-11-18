import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense_day_group.dart';

import '../../../../support/builders.dart';

void main() {
  group('ExpenseDayGroup.from', () {
    test('returns no groups for no expenses', () {
      expect(ExpenseDayGroup.from(const []), isEmpty);
    });

    test('groups expenses by calendar day and totals each day', () {
      final a = buildExpense(
        id: 'a',
        amountMinor: 500,
        date: DateTime(2026, 11, 17),
      );
      final b = buildExpense(
        id: 'b',
        amountMinor: 250,
        date: DateTime(2026, 11, 17),
      );
      final c = buildExpense(
        id: 'c',
        amountMinor: 1000,
        date: DateTime(2026, 11, 15),
      );

      final groups = ExpenseDayGroup.from([a, b, c]);

      expect(groups, hasLength(2));
      expect(groups[0].day, DateTime(2026, 11, 17));
      expect(groups[0].expenses, [a, b]);
      expect(groups[0].totalMinor, 750);
      expect(groups[1].day, DateTime(2026, 11, 15));
      expect(groups[1].expenses, [c]);
      expect(groups[1].totalMinor, 1000);
    });

    test(
      'keeps the order it was given, so newest first stays newest first',
      () {
        final newer = buildExpense(id: 'new', date: DateTime(2026, 11, 17));
        final older = buildExpense(id: 'old', date: DateTime(2026, 11, 1));

        final days = ExpenseDayGroup.from([newer, older]).map((g) => g.day);

        expect(days, [DateTime(2026, 11, 17), DateTime(2026, 11, 1)]);
      },
    );

    test('puts expenses with different times on the same day together', () {
      final morning = buildExpense(id: 'm', date: DateTime(2026, 11, 17, 8));
      final night = buildExpense(id: 'n', date: DateTime(2026, 11, 17, 22));

      final groups = ExpenseDayGroup.from([morning, night]);

      expect(groups, hasLength(1));
      expect(groups.single.expenses, hasLength(2));
    });
  });
}
