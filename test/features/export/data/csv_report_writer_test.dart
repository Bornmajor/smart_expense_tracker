import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/utils/currency.dart';
import 'package:smart_expense_tracker/features/export/data/writers/csv_report_writer.dart';
import 'package:smart_expense_tracker/features/export/domain/entities/monthly_report.dart';

void main() {
  const writer = CsvReportWriter();

  MonthlyReport reportOf(
    List<ReportRow> rows, {
    Currency currency = Currency.none,
  }) => MonthlyReport(
    month: DateTime(2026, 11),
    rows: rows,
    categories: const [],
    totalMinor: rows.fold(0, (sum, r) => sum + r.amountMinor),
    currency: currency,
  );

  ReportRow row({
    String title = '',
    String vendor = 'Cafe',
    String category = 'Food',
    int amountMinor = 1250,
    DateTime? date,
  }) => ReportRow(
    date: date ?? DateTime(2026, 11, 5),
    title: title,
    vendor: vendor,
    categoryName: category,
    amountMinor: amountMinor,
  );

  /// The file's text, without the byte order mark, split into lines.
  Future<List<String>> linesOf(MonthlyReport report) async {
    final file = await writer.write(report);
    final text = utf8.decode(file.bytes).replaceFirst('﻿', '');
    return text.split('\r\n')..removeLast(); // the text ends with a break
  }

  test('starts with the column names', () async {
    final lines = await linesOf(reportOf([row()]));

    expect(lines.first, 'Date,Title,Vendor,Category,Amount,Currency');
  });

  test(
    'writes one line per expense with a sortable date and plain amount',
    () async {
      final lines = await linesOf(
        reportOf([
          row(title: 'Lunch', vendor: 'Cafe', amountMinor: 1250),
          row(
            vendor: 'Bus',
            category: 'Transport',
            amountMinor: 123456,
            date: DateTime(2026, 11, 20),
          ),
        ]),
      );

      expect(lines, [
        'Date,Title,Vendor,Category,Amount,Currency',
        '2026-11-05,Lunch,Cafe,Food,12.50,',
        '2026-11-20,,Bus,Transport,1234.56,',
      ]);
    },
  );

  test('puts the currency code on every line', () async {
    final lines = await linesOf(
      reportOf([row(), row(vendor: 'Bus')], currency: Currency.kes),
    );

    expect(lines[1], endsWith(',12.50,KES'));
    expect(lines[2], endsWith(',12.50,KES'));
  });

  test('leaves the currency cell empty when there is no currency', () async {
    final lines = await linesOf(reportOf([row()]));

    expect(lines[1], endsWith(',12.50,'));
  });

  test('keeps the amount a plain number, whatever the currency', () async {
    final lines = await linesOf(
      reportOf([row(amountMinor: 123456)], currency: Currency.usd),
    );

    expect(lines[1], contains(',1234.56,'));
    expect(lines[1], isNot(contains(r"$")));
  });

  test('an empty month still has the header line', () async {
    final lines = await linesOf(reportOf(const []));

    expect(lines, ['Date,Title,Vendor,Category,Amount,Currency']);
  });

  test('is named for the month and typed as CSV', () async {
    final file = await writer.write(reportOf([row()]));

    expect(file.name, 'spendwise-iq-2026-11.csv');
    expect(file.mimeType, 'text/csv');
  });

  test('begins with a byte order mark so Excel reads accents', () async {
    final file = await writer.write(reportOf([row(vendor: 'Café')]));

    expect(file.bytes.take(3), [0xEF, 0xBB, 0xBF]);
    expect(utf8.decode(file.bytes), contains('Café'));
  });

  group('escaping', () {
    test('quotes a cell with a comma', () {
      expect(
        CsvReportWriter.escape('Smith, Jones & Co'),
        '"Smith, Jones & Co"',
      );
    });

    test('doubles a quote inside a cell', () {
      expect(CsvReportWriter.escape('The "best" cafe'), '"The ""best"" cafe"');
    });

    test('quotes a cell with a line break', () {
      expect(
        CsvReportWriter.escape('line one\nline two'),
        '"line one\nline two"',
      );
    });

    test('leaves a plain cell alone', () {
      expect(CsvReportWriter.escape('Corner Cafe'), 'Corner Cafe');
    });

    test('leaves an empty cell empty', () {
      expect(CsvReportWriter.escape(''), '');
    });

    for (final start in ['=', '+', '-', '@']) {
      test('defuses a cell starting with $start so it is not a formula', () {
        expect(CsvReportWriter.escape('${start}SUM(A1)'), "'${start}SUM(A1)");
      });
    }

    test('defuses and quotes a formula that also has a comma', () {
      expect(
        CsvReportWriter.escape('=HYPERLINK("x","y")'),
        '"\'=HYPERLINK(""x"",""y"")"',
      );
    });

    test('a vendor with a comma stays in one column', () async {
      final lines = await linesOf(reportOf([row(vendor: 'A, B')]));

      expect(lines[1], '2026-11-05,,"A, B",Food,12.50,');
    });
  });
}
