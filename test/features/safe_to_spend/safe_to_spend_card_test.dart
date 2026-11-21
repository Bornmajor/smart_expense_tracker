import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/core/utils/currency.dart';
import 'package:smart_expense_tracker/features/safe_to_spend/domain/entities/safe_to_spend.dart';
import 'package:smart_expense_tracker/features/safe_to_spend/presentation/widgets/safe_to_spend_card.dart';

void main() {
  Future<void> show(WidgetTester tester, SafeToSpend value) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SafeToSpendCard(safeToSpend: value, currency: Currency.kes),
          ),
        ),
      );

  testWidgets('shows an amount a day, what is left and the bills', (
    tester,
  ) async {
    await show(
      tester,
      const SafeToSpend(
        limitMinor: 6000000,
        spentMinor: 2500000,
        upcomingMinor: 1200000,
        daysLeft: 11,
      ),
    );

    expect(find.text('Safe to spend'), findsOneWidget);
    expect(find.textContaining('a day'), findsOneWidget);
    expect(find.textContaining('11 days to go'), findsOneWidget);
    expect(find.textContaining('of bills still to come'), findsOneWidget);
  });

  testWidgets('leaves out the bills line when none are coming', (tester) async {
    await show(
      tester,
      const SafeToSpend(
        limitMinor: 6000000,
        spentMinor: 0,
        upcomingMinor: 0,
        daysLeft: 1,
      ),
    );

    expect(find.textContaining('last day of the month'), findsOneWidget);
    expect(find.textContaining('bills still to come'), findsNothing);
  });

  testWidgets('says so when the budget is already spoken for', (tester) async {
    await show(
      tester,
      const SafeToSpend(
        limitMinor: 1000000,
        spentMinor: 900000,
        upcomingMinor: 300000,
        daysLeft: 5,
      ),
    );

    expect(find.text('Over budget'), findsOneWidget);
    expect(find.textContaining('over'), findsWidgets);
    expect(find.textContaining('a day'), findsNothing);
  });

  testWidgets('a big sum at large text shrinks instead of overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await show(
      tester,
      const SafeToSpend(
        limitMinor: 99999999999,
        spentMinor: 0,
        upcomingMinor: 0,
        daysLeft: 1,
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
