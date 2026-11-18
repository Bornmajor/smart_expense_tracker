import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense_day_group.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/widgets/day_header.dart';

void main() {
  final now = DateTime(2026, 11, 17, 12);

  Future<void> pumpHeader(WidgetTester tester, DateTime day, int total) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: DayHeader(
              group: ExpenseDayGroup(
                day: day,
                expenses: const [],
                totalMinor: total,
              ),
              now: now,
            ),
          ),
        ),
      );

  group('DayHeader', () {
    testWidgets('shows Today with the day total', (tester) async {
      await pumpHeader(tester, DateTime(2026, 11, 17), 75000);

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('750.00'), findsOneWidget);
    });

    testWidgets('shows Yesterday and short dates for older days', (
      tester,
    ) async {
      await pumpHeader(tester, DateTime(2026, 11, 16), 500);
      expect(find.text('Yesterday'), findsOneWidget);

      await pumpHeader(tester, DateTime(2026, 11, 10), 500);
      expect(find.text('Tue, Nov 10'), findsOneWidget);
    });

    testWidgets('is announced as a heading', (tester) async {
      await pumpHeader(tester, DateTime(2026, 11, 17), 500);

      final semantics = tester.getSemantics(find.text('Today'));
      expect(semantics.flagsCollection.isHeader, isTrue);
    });
  });
}
