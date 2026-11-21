import 'package:equatable/equatable.dart';

import 'expense.dart';

/// Which expenses a list shows. Every part is optional, and leaving one out
/// means "any". An expense has to pass all the parts that are set.
class ExpenseFilter extends Equatable {
  const ExpenseFilter({
    this.query = '',
    this.categoryId,
    this.month,
    this.from,
    this.to,
    this.minMinor,
    this.maxMinor,
  });

  /// Words to find in the vendor or the title. Every word has to be found, in
  /// any order, ignoring capital letters. Blank means any.
  final String query;

  /// Only expenses in this category.
  final String? categoryId;

  /// Only expenses in the month of this date (the day does not matter). Used
  /// by the Summary, which opens one category and month at a time.
  final DateTime? month;

  /// Only expenses on or after / on or before these days (the time of day
  /// does not matter).
  final DateTime? from;
  final DateTime? to;

  /// Only expenses of at least / at most this amount, in minor units.
  final int? minMinor;
  final int? maxMinor;

  /// How many of the choices in the filter sheet are in use: the category,
  /// the dates and the amount. The search words are counted separately,
  /// because they have their own field.
  int get activeCount =>
      (categoryId != null ? 1 : 0) +
      (from != null || to != null ? 1 : 0) +
      (minMinor != null || maxMinor != null ? 1 : 0);

  bool get hasQuery => query.trim().isNotEmpty;

  /// True when nothing limits the list.
  bool get isEmpty => !hasQuery && month == null && activeCount == 0;

  ExpenseFilter copyWith({
    String? query,
    String? categoryId,
    bool clearCategory = false,
    DateTime? from,
    DateTime? to,
    bool clearDates = false,
    int? minMinor,
    int? maxMinor,
    bool clearAmount = false,
  }) => ExpenseFilter(
    query: query ?? this.query,
    categoryId: clearCategory ? null : categoryId ?? this.categoryId,
    month: month,
    from: clearDates ? null : from ?? this.from,
    to: clearDates ? null : to ?? this.to,
    minMinor: clearAmount ? null : minMinor ?? this.minMinor,
    maxMinor: clearAmount ? null : maxMinor ?? this.maxMinor,
  );

  bool matches(Expense expense) {
    final category = categoryId;
    if (category != null && expense.categoryId != category) return false;

    final wanted = month;
    if (wanted != null &&
        (expense.date.year != wanted.year ||
            expense.date.month != wanted.month)) {
      return false;
    }

    final day = DateTime(
      expense.date.year,
      expense.date.month,
      expense.date.day,
    );
    final start = from;
    if (start != null && day.isBefore(_dayOnly(start))) return false;
    final end = to;
    if (end != null && day.isAfter(_dayOnly(end))) return false;

    final min = minMinor;
    if (min != null && expense.amountMinor < min) return false;
    final max = maxMinor;
    if (max != null && expense.amountMinor > max) return false;

    if (hasQuery) {
      final text = '${expense.vendor} ${expense.title}'.toLowerCase();
      for (final word in query.toLowerCase().split(RegExp(r'\s+'))) {
        if (word.isNotEmpty && !text.contains(word)) return false;
      }
    }
    return true;
  }

  static DateTime _dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  List<Object?> get props => [
    query.trim().toLowerCase(),
    categoryId,
    month?.year,
    month?.month,
    from == null ? null : _dayOnly(from!),
    to == null ? null : _dayOnly(to!),
    minMinor,
    maxMinor,
  ];
}
