import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:smart_expense_tracker/features/settings/domain/entities/app_theme_mode.dart';

import '../support/builders.dart';
import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  final today = DateTime.now();
  final thisMonth = DateTime(today.year, today.month, today.day);

  testWidgets('moves between the Expenses, Summary and Settings tabs', (
    tester,
  ) async {
    await pumpRouterApp(tester);
    expect(find.text('Add your first expense'), findsOneWidget);

    await goToTab(tester, 'Summary');
    expect(find.text('Total spent'), findsOneWidget);

    await goToTab(tester, 'Settings');
    expect(find.text('Appearance'), findsOneWidget);

    await goToTab(tester, 'Expenses');
    expect(find.text('Add your first expense'), findsOneWidget);
  });

  testWidgets('the add button is hidden on the Settings tab', (tester) async {
    await pumpRouterApp(tester);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    await goToTab(tester, 'Settings');

    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('the add sheet offers manual entry first and scan second', (
    tester,
  ) async {
    await pumpRouterApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Enter manually'), findsOneWidget);
    expect(find.text('Scan receipt'), findsOneWidget);
    final manualY = tester.getTopLeft(find.text('Enter manually')).dy;
    final scanY = tester.getTopLeft(find.text('Scan receipt')).dy;
    expect(manualY, lessThan(scanY));
  });

  testWidgets('choosing scan explains that it is coming soon', (tester) async {
    await pumpRouterApp(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tapText(tester, 'Scan receipt');

    expect(find.text('Receipt scanning is coming soon'), findsOneWidget);
  });

  group('Summary tab', () {
    testWidgets('shows the month total and spending by category', (
      tester,
    ) async {
      final expenses = FakeExpenseRepository(
        initial: [
          buildExpense(id: '1', amountMinor: 1500, date: thisMonth),
          buildExpense(
            id: '2',
            amountMinor: 500,
            date: thisMonth,
            categoryId: 'transport',
          ),
        ],
      );
      await pumpRouterApp(tester, expenses: expenses);

      await goToTab(tester, 'Summary');

      expect(find.text('20.00'), findsOneWidget);
      expect(find.text('2 expenses'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('15.00'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
    });

    testWidgets('goes to the previous month, and not past the current one', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
        expenses: FakeExpenseRepository(
          initial: [buildExpense(date: thisMonth)],
        ),
      );
      await goToTab(tester, 'Summary');

      final nextButton = find.widgetWithIcon(IconButton, Icons.chevron_right);
      expect(tester.widget<IconButton>(nextButton).onPressed, isNull);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      final previous = DateFormat.yMMMM().format(
        DateTime(today.year, today.month - 1),
      );
      expect(find.text(previous), findsOneWidget);
      expect(find.text('No expenses in $previous'), findsOneWidget);
      expect(tester.widget<IconButton>(nextButton).onPressed, isNotNull);

      await tester.tap(nextButton);
      await tester.pumpAndSettle();
      expect(find.text('Total spent'), findsOneWidget);
      expect(find.text('No expenses in $previous'), findsNothing);
    });
  });

  group('Settings tab', () {
    testWidgets('changes and remembers the theme', (tester) async {
      final settings = FakeSettingsRepository();
      await pumpRouterApp(tester, settings: settings);
      await goToTab(tester, 'Settings');

      await tapText(tester, 'Dark');

      expect(settings.mode, AppThemeMode.dark);
    });

    testWidgets('shows the About details', (tester) async {
      await pumpRouterApp(tester);
      await goToTab(tester, 'Settings');

      await tapText(tester, 'Your data stays on this device');

      expect(find.byType(AboutDialog), findsOneWidget);
    });
  });
}
