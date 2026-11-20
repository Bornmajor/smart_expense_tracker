import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/export/data/writers/pdf_report_writer.dart';
import 'package:smart_expense_tracker/features/export/domain/entities/monthly_report.dart';

void main() {
  /// The real Inter files, the same as the app embeds.
  final writer = PdfReportWriter(
    loadFonts: () async => (
      regular: File('assets/fonts/Inter-Regular.ttf').readAsBytesSync(),
      bold: File('assets/fonts/Inter-Bold.ttf').readAsBytesSync(),
    ),
    now: () => DateTime(2026, 12, 1),
  );

  ReportRow row(int i, {String vendor = 'Cafe', String title = ''}) =>
      ReportRow(
        date: DateTime(2026, 11, 1 + i % 28),
        title: title,
        vendor: vendor,
        categoryName: 'Food',
        amountMinor: 1000 + i,
      );

  MonthlyReport reportOf(List<ReportRow> rows) => MonthlyReport(
    month: DateTime(2026, 11),
    rows: rows,
    categories: [
      ReportCategory(
        name: 'Food',
        totalMinor: rows.fold(0, (sum, r) => sum + r.amountMinor),
        share: 1,
      ),
    ],
    totalMinor: rows.fold(0, (sum, r) => sum + r.amountMinor),
  );

  /// How many pages the PDF has, read from its page tree.
  int pageCount(List<int> bytes) {
    final text = latin1.decode(bytes);
    final match = RegExp(r'/Count (\d+)').firstMatch(text);
    return int.parse(match!.group(1)!);
  }

  test('makes a PDF file named for the month', () async {
    final file = await writer.write(reportOf([row(1)]));

    expect(latin1.decode(file.bytes.sublist(0, 5)), '%PDF-');
    expect(file.name, 'spendwise-iq-2026-11.pdf');
    expect(file.mimeType, 'application/pdf');
  });

  test('a short month fits on one page', () async {
    final file = await writer.write(
      reportOf([for (var i = 0; i < 5; i++) row(i)]),
    );

    expect(pageCount(file.bytes), 1);
  });

  test('a long month continues on more pages', () async {
    final file = await writer.write(
      reportOf([for (var i = 0; i < 150; i++) row(i)]),
    );

    expect(pageCount(file.bytes), greaterThan(1));
  });

  test('accents, symbols and very long names do not break it', () async {
    final file = await writer.write(
      reportOf([
        row(1, vendor: 'Café Zoë – Crème & Co.', title: 'Déjeuner d\'équipe'),
        row(2, vendor: 'Ñandú €£¥ ${'very long name ' * 20}'),
        row(3, vendor: '', title: ''),
      ]),
    );

    expect(file.bytes, isNotEmpty);
    expect(pageCount(file.bytes), greaterThanOrEqualTo(1));
  });

  test(
    'embeds the font, so it does not depend on the reader\'s fonts',
    () async {
      final file = await writer.write(reportOf([row(1)]));

      expect(latin1.decode(file.bytes), contains('Inter'));
    },
  );
}
