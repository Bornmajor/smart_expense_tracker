import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/utils/money.dart';
import '../../domain/entities/export_format.dart';
import '../../domain/entities/monthly_report.dart';
import '../../domain/entities/report_file.dart';
import '../../domain/repositories/report_writer.dart';

/// The font files for the PDF. PDF's built-in fonts cannot draw accents or
/// many symbols, so the real Inter files are embedded instead.
typedef PdfFontBytes = ({Uint8List regular, Uint8List bold});

/// A readable monthly report: the total, spending by category, then every
/// expense in a table that continues over as many pages as it needs.
class PdfReportWriter implements ReportWriter {
  PdfReportWriter({required this._loadFonts, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final Future<PdfFontBytes> Function() _loadFonts;
  final DateTime Function() _now;

  static const _ink = PdfColors.grey900;
  static const _muted = PdfColors.grey700;
  static const _line = PdfColors.grey400;
  static const _band = PdfColors.grey200;

  @override
  Future<ReportFile> write(MonthlyReport report) async {
    final bytes = await _loadFonts();
    final regular = pw.Font.ttf(ByteData.sublistView(bytes.regular));
    final bold = pw.Font.ttf(ByteData.sublistView(bytes.bold));

    final document = pw.Document(
      title: 'SpendWise IQ ${DateFormat.yMMMM().format(report.month)}',
      creator: 'SpendWise IQ',
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    final generated = DateFormat.yMMMd().format(_now());
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => context.pageNumber == 1
            ? pw.SizedBox()
            : pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Text(
                  'SpendWise IQ  ·  ${DateFormat.yMMMM().format(report.month)}',
                  style: const pw.TextStyle(fontSize: 9, color: _muted),
                ),
              ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Made with SpendWise IQ on $generated',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
        build: (context) => [
          pw.Text(
            DateFormat.yMMMM().format(report.month),
            style: pw.TextStyle(font: bold, fontSize: 24, color: _ink),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Expense report',
            style: const pw.TextStyle(fontSize: 11, color: _muted),
          ),
          pw.SizedBox(height: 18),
          _totalBox(report, bold),
          pw.SizedBox(height: 22),
          _sectionTitle('By category', bold),
          _categoryTable(report, bold),
          pw.SizedBox(height: 22),
          _sectionTitle('All expenses', bold),
          _expenseTable(report, bold),
        ],
      ),
    );

    return ReportFile(
      name: report.fileName(ExportFormat.pdf.extension),
      mimeType: ExportFormat.pdf.mimeType,
      bytes: await document.save(),
    );
  }

  pw.Widget _sectionTitle(String text, pw.Font bold) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(
      text,
      style: pw.TextStyle(font: bold, fontSize: 13, color: _ink),
    ),
  );

  pw.Widget _totalBox(MonthlyReport report, pw.Font bold) {
    final count = report.rows.length;
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _band,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Total spent',
            style: const pw.TextStyle(fontSize: 10, color: _muted),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            report.currency.formatWithCode(report.totalMinor),
            style: pw.TextStyle(font: bold, fontSize: 26, color: _ink),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            count == 1 ? '1 expense' : '$count expenses',
            style: const pw.TextStyle(fontSize: 10, color: _muted),
          ),
        ],
      ),
    );
  }

  pw.Widget _categoryTable(MonthlyReport report, pw.Font bold) {
    return _table(
      bold: bold,
      headers: ['Category', 'Share', _amountHeader(report)],
      rows: [
        for (final c in report.categories)
          [c.name, '${(c.share * 100).round()}%', Money.format(c.totalMinor)],
      ],
      widths: const [4, 1, 2],
      // Numbers line up on the right.
      rightAligned: const {1, 2},
    );
  }

  pw.Widget _expenseTable(MonthlyReport report, pw.Font bold) {
    final dateFormat = DateFormat.yMMMd();
    return _table(
      bold: bold,
      headers: ['Date', 'Description', 'Category', _amountHeader(report)],
      rows: [
        for (final row in report.rows)
          [
            dateFormat.format(row.date),
            _description(row),
            row.categoryName,
            Money.format(row.amountMinor),
          ],
      ],
      widths: const [2, 4, 2.4, 2],
      rightAligned: const {3},
    );
  }

  /// "Amount (KES)": the code, not the symbol, because a PDF reader may lack
  /// the symbol's glyph.
  String _amountHeader(MonthlyReport report) => report.currency.code.isEmpty
      ? 'Amount'
      : 'Amount (${report.currency.code})';

  /// The title when there is one, with the vendor after it.
  String _description(ReportRow row) {
    if (row.title.isEmpty) return row.vendor;
    return '${row.title}  ·  ${row.vendor}';
  }

  /// The look shared by both tables. The header row repeats on every page.
  pw.Widget _table({
    required pw.Font bold,
    required List<String> headers,
    required List<List<String>> rows,
    required List<double> widths,
    required Set<int> rightAligned,
  }) {
    final alignments = {
      for (var i = 0; i < headers.length; i++)
        i: rightAligned.contains(i)
            ? pw.Alignment.centerRight
            : pw.Alignment.centerLeft,
    };
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(font: bold, fontSize: 9, color: _ink),
      cellStyle: const pw.TextStyle(fontSize: 9, color: _ink),
      headerDecoration: const pw.BoxDecoration(color: _band),
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _line, width: 0.4),
        bottom: pw.BorderSide(color: _line, width: 0.4),
      ),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      columnWidths: {
        for (var i = 0; i < widths.length; i++)
          i: pw.FlexColumnWidth(widths[i]),
      },
      cellAlignments: alignments,
      headerAlignments: alignments,
    );
  }
}
