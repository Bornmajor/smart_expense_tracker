import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';

import '../../../../core/utils/money.dart';
import '../../domain/entities/export_format.dart';
import '../../domain/entities/monthly_report.dart';
import '../../domain/entities/report_file.dart';
import '../../domain/repositories/report_writer.dart';

/// One expense per row, for opening in a spreadsheet: Date, Title, Vendor,
/// Category, Amount. Dates are year-month-day and amounts are plain numbers
/// such as 1234.50, so a spreadsheet can sort and add them up.
class CsvReportWriter implements ReportWriter {
  const CsvReportWriter();

  static const header = ['Date', 'Title', 'Vendor', 'Category', 'Amount'];

  @override
  Future<ReportFile> write(MonthlyReport report) async {
    final format = DateFormat('yyyy-MM-dd');
    final lines = [
      header,
      for (final row in report.rows)
        [
          format.format(row.date),
          row.title,
          row.vendor,
          row.categoryName,
          Money.toInputText(row.amountMinor),
        ],
    ];

    // Windows line endings are what the CSV standard asks for. The byte order
    // mark at the start makes Excel read accents and symbols correctly.
    final text = '﻿${lines.map(_line).join('\r\n')}\r\n';
    return ReportFile(
      name: report.fileName(ExportFormat.csv.extension),
      mimeType: ExportFormat.csv.mimeType,
      bytes: Uint8List.fromList(utf8.encode(text)),
    );
  }

  String _line(List<String> cells) => cells.map(escape).join(',');

  /// Quotes a cell when it holds a comma, quote or line break.
  ///
  /// A cell that starts with `=`, `+`, `-` or `@` would be run as a formula by
  /// a spreadsheet, so a vendor typed as `=HYPERLINK(...)` could do harm.
  /// Those cells get a leading apostrophe, which makes them plain text.
  static String escape(String cell) {
    var value = cell;
    if (value.isNotEmpty && '=+-@\t\r'.contains(value[0])) {
      value = "'$value";
    }
    final needsQuotes = value.contains(RegExp(r'[",\r\n]'));
    return needsQuotes ? '"${value.replaceAll('"', '""')}"' : value;
  }
}
