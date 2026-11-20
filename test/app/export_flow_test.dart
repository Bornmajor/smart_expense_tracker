import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:smart_expense_tracker/features/export/domain/export_exception.dart';

import '../support/builders.dart';
import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  final today = DateTime.now();
  final thisMonth = DateTime(today.year, today.month);
  final monthLabel = DateFormat.yMMMM().format(thisMonth);

  final exportButton = find.byTooltip('Export this month');

  late FakeReportSharer sharer;
  late FakeReportWriter pdf;
  late FakeReportWriter csv;

  setUp(() {
    sharer = FakeReportSharer();
    pdf = FakeReportWriter('pdf');
    csv = FakeReportWriter('csv');
  });

  Future<void> openSummary(
    WidgetTester tester, {
    List<Expense>? expenses,
  }) async {
    await pumpRouterApp(
      tester,
      expenses: FakeExpenseRepository(
        initial: expenses ?? [buildExpense(date: today, amountMinor: 2500)],
      ),
      sharer: sharer,
      pdfWriter: pdf,
      csvWriter: csv,
    );
    await goToTab(tester, 'Summary');
  }

  testWidgets('offers a PDF and a CSV for the month on screen', (tester) async {
    await openSummary(tester);

    await tester.tap(exportButton);
    await tester.pumpAndSettle();

    expect(find.text('Export $monthLabel'), findsOneWidget);
    expect(find.text('PDF report'), findsOneWidget);
    expect(find.text('CSV spreadsheet'), findsOneWidget);
  });

  testWidgets('the sheet covers the Add expense button and the tab bar', (
    tester,
  ) async {
    await openSummary(tester);
    // Before the sheet opens, both can be tapped.
    expect(find.text('Add expense').hitTestable(), findsOneWidget);

    await tester.tap(exportButton);
    await tester.pumpAndSettle();

    // Nothing from the shell may sit on top of the sheet or its backdrop.
    expect(find.text('Add expense').hitTestable(), findsNothing);
    expect(
      find
          .descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Settings'),
          )
          .hitTestable(),
      findsNothing,
    );
    expect(find.text('PDF report').hitTestable(), findsOneWidget);
  });

  testWidgets('shares a PDF for this month', (tester) async {
    await openSummary(tester);

    await tester.tap(exportButton);
    await tester.pumpAndSettle();
    await tapText(tester, 'PDF report');

    final mm = thisMonth.month.toString().padLeft(2, '0');
    expect(sharer.shared.single.name, 'spendwise-iq-${thisMonth.year}-$mm.pdf');
    expect(pdf.reports.single.totalMinor, 2500);
    expect(csv.reports, isEmpty);
  });

  testWidgets('shares a CSV when that is chosen', (tester) async {
    await openSummary(tester);

    await tester.tap(exportButton);
    await tester.pumpAndSettle();
    await tapText(tester, 'CSV spreadsheet');

    expect(sharer.shared.single.name, endsWith('.csv'));
    expect(csv.reports, hasLength(1));
    expect(pdf.reports, isEmpty);
  });

  testWidgets('exports the earlier month after switching to it', (
    tester,
  ) async {
    final lastMonth = DateTime(today.year, today.month - 1, 10);
    await openSummary(
      tester,
      expenses: [
        buildExpense(id: 'now', date: today, amountMinor: 2500),
        buildExpense(id: 'old', date: lastMonth, amountMinor: 700),
      ],
    );

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    await tester.tap(exportButton);
    await tester.pumpAndSettle();
    expect(
      find.text('Export ${DateFormat.yMMMM().format(lastMonth)}'),
      findsOneWidget,
    );
    await tapText(tester, 'CSV spreadsheet');

    expect(csv.reports.single.totalMinor, 700);
  });

  testWidgets('closing the sheet shares nothing', (tester) async {
    await openSummary(tester);

    await tester.tap(exportButton);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(sharer.shared, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('is switched off for a month with no expenses', (tester) async {
    await openSummary(tester, expenses: const []);

    final button = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.ios_share),
        matching: find.byType(IconButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('shows a progress indicator while the report is made', (
    tester,
  ) async {
    final release = Completer<void>();
    sharer.gate = release.future;
    await openSummary(tester);

    await tester.tap(exportButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('PDF report'));
    // The spinner animates forever, so settle only the closing sheet.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    // The button is replaced, so a second export cannot be started.
    expect(exportButton, findsNothing);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );

    release.complete();
    await tester.pumpAndSettle();

    expect(exportButton, findsOneWidget);
    expect(sharer.shared, hasLength(1));
  });

  testWidgets('tells the user when the share sheet cannot open', (
    tester,
  ) async {
    sharer.error = const ExportException(ExportProblem.couldNotShare);
    await openSummary(tester);

    await tester.tap(exportButton);
    await tester.pumpAndSettle();
    await tapText(tester, 'PDF report');

    expect(find.textContaining('share sheet'), findsOneWidget);
    expect(exportButton, findsOneWidget);
  });

  testWidgets('tells the user when the report cannot be made', (tester) async {
    sharer.error = StateError('bug');
    await openSummary(tester);

    await tester.tap(exportButton);
    await tester.pumpAndSettle();
    await tapText(tester, 'PDF report');

    expect(find.textContaining('make the report'), findsOneWidget);
    // The screen is usable again.
    expect(exportButton, findsOneWidget);
  });
}
