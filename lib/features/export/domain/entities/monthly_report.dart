import 'package:equatable/equatable.dart';

/// One expense as it appears in a report, with the category's name already
/// looked up.
class ReportRow extends Equatable {
  const ReportRow({
    required this.date,
    required this.title,
    required this.vendor,
    required this.categoryName,
    required this.amountMinor,
  });

  final DateTime date;

  /// Empty when the expense has no title.
  final String title;
  final String vendor;
  final String categoryName;
  final int amountMinor;

  @override
  List<Object?> get props => [date, title, vendor, categoryName, amountMinor];
}

/// How much was spent in one category during the month.
class ReportCategory extends Equatable {
  const ReportCategory({
    required this.name,
    required this.totalMinor,
    required this.share,
  });

  final String name;
  final int totalMinor;

  /// Fraction of the month's total, from 0 to 1.
  final double share;

  @override
  List<Object?> get props => [name, totalMinor, share];
}

/// Everything a report shows for one calendar month. Both the PDF and the CSV
/// are made from this, so they always agree.
class MonthlyReport extends Equatable {
  const MonthlyReport({
    required this.month,
    required this.rows,
    required this.categories,
    required this.totalMinor,
  });

  /// First day of the month.
  final DateTime month;

  /// Oldest first.
  final List<ReportRow> rows;

  /// Largest spending first.
  final List<ReportCategory> categories;
  final int totalMinor;

  /// Name for the exported file, such as "spendwise-iq-2026-11.pdf".
  String fileName(String extension) {
    final mm = month.month.toString().padLeft(2, '0');
    return 'spendwise-iq-${month.year}-$mm.$extension';
  }

  @override
  List<Object?> get props => [month, rows, categories, totalMinor];
}
