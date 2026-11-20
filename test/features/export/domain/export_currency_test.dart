import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/utils/currency.dart';
import 'package:smart_expense_tracker/features/export/data/writers/csv_report_writer.dart';
import 'package:smart_expense_tracker/features/export/data/writers/pdf_report_writer.dart';
import 'package:smart_expense_tracker/features/export/domain/entities/export_format.dart';
import 'package:smart_expense_tracker/features/export/domain/usecases/build_monthly_report.dart';
import 'package:smart_expense_tracker/features/export/domain/usecases/export_month.dart';

import '../../../support/builders.dart';
import '../../../support/fakes.dart';

/// Reports are written in the currency chosen in Settings.
void main() {
  final november = DateTime(2026, 11);
  final categories = FakeCategoryRepository();

  group('BuildMonthlyReport', () {
    test('carries the currency into the report', () {
      final report = const BuildMonthlyReport()(
        [buildExpense()],
        categories.categories,
        november,
        currency: Currency.kes,
      );

      expect(report.currency, Currency.kes);
    });

    test('does not change any amount because of the currency', () {
      final expenses = [buildExpense(amountMinor: 123456)];

      final kes = const BuildMonthlyReport()(
        expenses,
        categories.categories,
        november,
        currency: Currency.kes,
      );
      final usd = const BuildMonthlyReport()(
        expenses,
        categories.categories,
        november,
        currency: Currency.usd,
      );

      expect(kes.totalMinor, usd.totalMinor);
      expect(kes.rows, usd.rows);
    });
  });

  group('ExportMonth', () {
    late FakeReportWriter csv;
    late Currency chosen;
    late ExportMonth export;

    setUp(() {
      csv = FakeReportWriter('csv');
      chosen = Currency.kes;
      export = ExportMonth(
        expenses: FakeExpenseRepository(initial: [buildExpense()]),
        categories: categories,
        pdf: FakeReportWriter('pdf'),
        csv: csv,
        sharer: FakeReportSharer(),
        currency: () => chosen,
      );
    });

    test('writes the report in the chosen currency', () async {
      await export(november, ExportFormat.csv);

      expect(csv.reports.single.currency, Currency.kes);
    });

    test(
      'uses the currency chosen at the time, not when it was built',
      () async {
        await export(november, ExportFormat.csv);
        chosen = Currency.usd;
        await export(november, ExportFormat.csv);

        expect(csv.reports.map((r) => r.currency), [
          Currency.kes,
          Currency.usd,
        ]);
      },
    );
  });

  group('the files', () {
    final pdfWriter = PdfReportWriter(
      loadFonts: () async => (
        regular: File('assets/fonts/Inter-Regular.ttf').readAsBytesSync(),
        bold: File('assets/fonts/Inter-Bold.ttf').readAsBytesSync(),
      ),
      now: () => DateTime(2026, 12, 1),
    );

    Future<List<int>> pdfFor(Currency currency) async {
      final report = const BuildMonthlyReport()(
        [buildExpense(amountMinor: 123456)],
        categories.categories,
        november,
        currency: currency,
      );
      return (await pdfWriter.write(report)).bytes;
    }

    test('a PDF is made for every currency in the list', () async {
      for (final currency in Currency.all) {
        final bytes = await pdfFor(currency);

        expect(
          latin1.decode(bytes.sublist(0, 5)),
          '%PDF-',
          reason: currency.name,
        );
      }
    });

    test('the CSV names the currency on each line', () async {
      final report = const BuildMonthlyReport()(
        [buildExpense(amountMinor: 123456)],
        categories.categories,
        november,
        currency: Currency.kes,
      );

      final text = utf8.decode(
        (await const CsvReportWriter().write(report)).bytes,
      );

      expect(text, contains('Amount,Currency'));
      expect(text, contains(',1234.56,KES'));
    });
  });
}
