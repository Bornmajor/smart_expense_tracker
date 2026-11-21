import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/core/utils/currency.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:smart_expense_tracker/features/home/presentation/widgets/money_card.dart';
import 'package:smart_expense_tracker/features/home/presentation/widgets/year_chart.dart';
import 'package:smart_expense_tracker/features/safe_to_spend/domain/entities/safe_to_spend.dart';

Widget host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('MoneyCard', () {
    const budget = Budget(scopeId: Budget.overallId, limitMinor: 6000000);

    Widget card({
      int spent = 2500000,
      Budget? budget = budget,
      SafeToSpend? safe,
      VoidCallback? onOpen,
      VoidCallback? onSetBudget,
    }) => host(
      MoneyCard(
        spentMinor: spent,
        currency: Currency.kes,
        budget: budget,
        safeToSpend: safe,
        onOpen: onOpen ?? () {},
        onSetBudget: onSetBudget ?? () {},
      ),
    );

    testWidgets('with a budget shows what is left and what is safe each day', (
      tester,
    ) async {
      await tester.pumpWidget(
        card(
          safe: const SafeToSpend(
            limitMinor: 6000000,
            spentMinor: 2500000,
            upcomingMinor: 0,
            daysLeft: 10,
          ),
        ),
      );

      expect(find.text('This month'), findsOneWidget);
      expect(find.textContaining('left'), findsOneWidget);
      expect(find.textContaining('a day · 10 days to go'), findsOneWidget);
      expect(find.text('Set a monthly budget'), findsNothing);
    });

    testWidgets('past the budget says how much over, in plain words', (
      tester,
    ) async {
      await tester.pumpWidget(
        card(
          spent: 7000000,
          safe: const SafeToSpend(
            limitMinor: 6000000,
            spentMinor: 7000000,
            upcomingMinor: 0,
            daysLeft: 3,
          ),
        ),
      );

      expect(find.textContaining('over'), findsOneWidget);
      expect(find.textContaining('already spoken for'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('without a budget invites the user to set one', (tester) async {
      var opened = false;
      await tester.pumpWidget(
        card(budget: null, onSetBudget: () => opened = true),
      );

      expect(find.text('Spent this month'), findsOneWidget);
      await tester.tap(find.text('Set a monthly budget'));

      expect(opened, isTrue);
    });

    testWidgets('tapping the card opens the month', (tester) async {
      var opened = false;
      await tester.pumpWidget(card(onOpen: () => opened = true));

      await tester.tap(find.text('This month'));

      expect(opened, isTrue);
    });

    testWidgets('a huge sum at large text shrinks instead of overflowing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(card(spent: 99999999999));

      expect(tester.takeException(), isNull);
    });
  });

  group('YearChart', () {
    List<int> totals() => [100000, 0, 250000, 0, 0, 0, 0, 0, 0, 0, 500000, 0];

    Widget chart({int current = 11, ValueChanged<int>? onTap}) => host(
      YearChart(
        year: 2026,
        totals: totals(),
        currentMonth: current,
        currency: Currency.kes,
        onMonthTap: onTap ?? (_) {},
      ),
    );

    testWidgets('has a bar for each month and the year in the title', (
      tester,
    ) async {
      await tester.pumpWidget(chart());

      expect(find.text('Spending in 2026'), findsOneWidget);
      expect(find.byType(InkWell), findsNWidgets(12));
    });

    testWidgets('each bar can be read out with its month and amount', (
      tester,
    ) async {
      await tester.pumpWidget(chart());

      expect(find.bySemanticsLabel(RegExp('^March: ')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^November: ')), findsOneWidget);
    });

    testWidgets('tapping a month reports it', (tester) async {
      final tapped = <int>[];
      await tester.pumpWidget(chart(onTap: tapped.add));

      await tester.tap(find.bySemanticsLabel(RegExp('^March: ')));

      expect(tapped, [3]);
    });

    testWidgets('a month still to come cannot be opened', (tester) async {
      final tapped = <int>[];
      await tester.pumpWidget(chart(current: 4, onTap: tapped.add));

      await tester.tap(find.bySemanticsLabel(RegExp('^December: ')));

      expect(tapped, isEmpty);
    });

    testWidgets('a year with nothing spent still draws', (tester) async {
      await tester.pumpWidget(
        host(
          YearChart(
            year: 2026,
            totals: List.filled(12, 0),
            currentMonth: 1,
            currency: Currency.kes,
            onMonthTap: (_) {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('fits a narrow phone at large text', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(chart());

      expect(tester.takeException(), isNull);
    });
  });
}
