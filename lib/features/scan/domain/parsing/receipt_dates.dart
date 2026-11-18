/// Finds the purchase date on a receipt from its text lines.
///
/// Numeric dates are read day-first (03/04/2026 is 3 April), as in most of the
/// world. When that gives an impossible or future date, the other order is
/// tried, so 11/16/2026 still reads as 16 November.
abstract final class ReceiptDates {
  static const _months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  static const _monthNames =
      r'(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\.?';

  /// 2026-11-16 or 2026/11/16
  static final _yearFirst = RegExp(
    r'\b(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})(?!\d)',
  );

  /// 16/11/2026, 16-11-26 or 16.11.2026
  static final _numeric = RegExp(
    r'\b(\d{1,2})[-/.](\d{1,2})[-/.](\d{4}|\d{2})\b',
  );

  /// 16 Nov 2026 or 16th November, 2026
  static final _dayMonthName = RegExp(
    r'\b(\d{1,2})(?:st|nd|rd|th)?[\s-]+' +
        _monthNames +
        r',?[\s-]+(\d{4}|\d{2})\b',
    caseSensitive: false,
  );

  /// Nov 16, 2026 or November 16 2026
  static final _monthNameFirst = RegExp(
    r'\b' + _monthNames + r'\s+(\d{1,2})(?:st|nd|rd|th)?,?\s+(\d{4})\b',
    caseSensitive: false,
  );

  /// The first valid date, reading lines from the top. Dates in the future
  /// are ignored, since a receipt cannot be from tomorrow.
  static DateTime? find(List<String> lines, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    for (final line in lines) {
      final date =
          _fromYearFirst(line, today) ??
          _fromNumeric(line, today) ??
          _fromDayMonthName(line, today) ??
          _fromMonthNameFirst(line, today);
      if (date != null) return date;
    }
    return null;
  }

  static DateTime? _fromYearFirst(String line, DateTime today) {
    for (final m in _yearFirst.allMatches(line)) {
      final date = _valid(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
        today,
      );
      if (date != null) return date;
    }
    return null;
  }

  static DateTime? _fromNumeric(String line, DateTime today) {
    for (final m in _numeric.allMatches(line)) {
      final first = int.parse(m.group(1)!);
      final second = int.parse(m.group(2)!);
      final year = _year(m.group(3)!);

      // Day-first, then month-first.
      final date =
          _valid(year, second, first, today) ??
          _valid(year, first, second, today);
      if (date != null) return date;
    }
    return null;
  }

  static DateTime? _fromDayMonthName(String line, DateTime today) {
    for (final m in _dayMonthName.allMatches(line)) {
      final date = _valid(
        _year(m.group(3)!),
        _months[m.group(2)!.toLowerCase()]!,
        int.parse(m.group(1)!),
        today,
      );
      if (date != null) return date;
    }
    return null;
  }

  static DateTime? _fromMonthNameFirst(String line, DateTime today) {
    for (final m in _monthNameFirst.allMatches(line)) {
      final date = _valid(
        int.parse(m.group(3)!),
        _months[m.group(1)!.toLowerCase()]!,
        int.parse(m.group(2)!),
        today,
      );
      if (date != null) return date;
    }
    return null;
  }

  /// Two-digit years are 2000 and later.
  static int _year(String text) {
    final year = int.parse(text);
    return text.length == 2 ? 2000 + year : year;
  }

  /// The date when it exists on the calendar, is not before 2000, and is not
  /// after today. Otherwise null.
  static DateTime? _valid(int year, int month, int day, DateTime today) {
    if (year < 2000 || month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    final date = DateTime(year, month, day);
    // DateTime rolls 31 February over to March; a real date keeps its parts.
    if (date.month != month || date.day != day) return null;
    return date.isAfter(today) ? null : date;
  }
}
