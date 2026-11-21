import '../../../../core/utils/money.dart';
import '../entities/quick_add_draft.dart';

/// Reads one typed line such as "lunch 350 at Java House yesterday" into an
/// amount, a date, a vendor and a title. Plain rules on the phone, nothing is
/// sent anywhere. It only guesses, so the user always checks the form.
///
/// What it understands:
/// - **Amount:** "350", "1,200", "12.50", "1.5k" (thousands), with or without
///   "ksh", "kes", "sh", "$" or "/=" around it. With several numbers, one with
///   such a marker wins, then the biggest.
/// - **Date:** today, yesterday, "day before yesterday", Swahili "leo", "jana"
///   and "juzi", a weekday ("monday", "last fri"), "12 nov", "nov 12",
///   "12th November 2026", and "12/11" or "12/11/2026" (day first).
/// - **Vendor:** the words after "at", "@" or "from".
/// - **Title:** the other words.
class ParseQuickAdd {
  ParseQuickAdd({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

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
      'jan(?:uary)?|feb(?:ruary)?|mar(?:ch)?|apr(?:il)?|may|june?|july?|'
      r'aug(?:ust)?|sept?(?:ember)?|oct(?:ober)?|nov(?:ember)?|dec(?:ember)?';

  static final _numericDate = RegExp(
    r'(?<![\d.,/-])(?:on\s+)?(\d{1,2})[/-](\d{1,2})(?:[/-](20\d{2}|\d{2}))?(?![\d/-])',
    caseSensitive: false,
  );
  static final _dayThenMonth = RegExp(
    r'(?<![\w.])(?:on\s+)?(\d{1,2})(?:st|nd|rd|th)?\s+(?:of\s+)?'
    '($_monthNames)\\b\\.?(?:\\s+(20\\d{2})\\b)?',
    caseSensitive: false,
  );
  static final _monthThenDay = RegExp(
    '(?<![\\w.])(?:on\\s+)?($_monthNames)\\b\\.?\\s+'
    r'(\d{1,2})(?:st|nd|rd|th)?\b(?:,?\s+(20\d{2})\b)?',
    caseSensitive: false,
  );
  static final _dayBefore = RegExp(
    r'\b(?:the\s+)?day\s+before\s+yesterday\b|\bjuzi\b',
    caseSensitive: false,
  );
  static final _yesterday = RegExp(
    r'\byesterday\b|\bjana\b',
    caseSensitive: false,
  );
  static final _today = RegExp(r'\btoday\b|\bleo\b', caseSensitive: false);
  static final _weekday = RegExp(
    r'\b(?:(?:last|on|this)\s+)?'
    r'(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
    caseSensitive: false,
  );
  static final _shortWeekday = RegExp(
    r'\b(?:last|on)\s+(mon|tues?|wed|thur?s?|fri|sat|sun)\b',
    caseSensitive: false,
  );
  static const _weekdayNumbers = {
    'mon': DateTime.monday,
    'tue': DateTime.tuesday,
    'wed': DateTime.wednesday,
    'thu': DateTime.thursday,
    'fri': DateTime.friday,
    'sat': DateTime.saturday,
    'sun': DateTime.sunday,
  };

  static final _amount = RegExp(
    r'(?<![\w.,])(?:(ksh|kshs|kes|sh|shs|usd|bob)\.?\s*|(\$)\s*)?'
    r'(\d{1,3}(?:,\d{3})+|\d+)(\.\d{1,2})?(k)?'
    r'(?:\s*(/=|/-|ksh|kshs|kes|shs|bob)(?![\w]))?(?![\w.,]*\d)(?![a-z])',
    caseSensitive: false,
  );

  static final _vendorWord = RegExp(
    r'(?:^|\s)(?:at|from|@)(?=\s|$)',
    caseSensitive: false,
  );
  static final _leadingFiller = RegExp(
    r'^\s*(?:spent|paid|bought|got)\b(?:\s+(?:on|for))?',
    caseSensitive: false,
  );

  QuickAddDraft call(String input) {
    var text = input.trim();
    if (text.isEmpty) return const QuickAddDraft();

    final today = _dayOnly(_now());
    final (date, withoutDate) = _takeDate(text, today);
    final (amount, withoutAmount) = _takeAmount(withoutDate);
    final (vendor, title) = _split(withoutAmount);

    return QuickAddDraft(
      amountMinor: amount,
      date: date,
      vendor: _titleCase(vendor),
      title: _capitalizeFirst(title),
    );
  }

  // ---- date ----

  (DateTime?, String) _takeDate(String text, DateTime today) {
    for (final take in [_numericDay, _namedDay, _relativeDay, _weekdayDay]) {
      final found = take(text, today);
      if (found != null) return found;
    }
    return (null, text);
  }

  (DateTime, String)? _numericDay(String text, DateTime today) {
    for (final match in _numericDate.allMatches(text)) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = match.group(3);
      final date = _build(
        today,
        day,
        month,
        year == null ? null : _fullYear(year),
      );
      if (date != null) return (date, _remove(text, match));
    }
    return null;
  }

  (DateTime, String)? _namedDay(String text, DateTime today) {
    for (final match in _dayThenMonth.allMatches(text)) {
      final date = _build(
        today,
        int.parse(match.group(1)!),
        _months[match.group(2)!.substring(0, 3).toLowerCase()]!,
        match.group(3) == null ? null : int.parse(match.group(3)!),
      );
      if (date != null) return (date, _remove(text, match));
    }
    for (final match in _monthThenDay.allMatches(text)) {
      final date = _build(
        today,
        int.parse(match.group(2)!),
        _months[match.group(1)!.substring(0, 3).toLowerCase()]!,
        match.group(3) == null ? null : int.parse(match.group(3)!),
      );
      if (date != null) return (date, _remove(text, match));
    }
    return null;
  }

  (DateTime, String)? _relativeDay(String text, DateTime today) {
    for (final (pattern, back) in [
      (_dayBefore, 2),
      (_yesterday, 1),
      (_today, 0),
    ]) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return (
          DateTime(today.year, today.month, today.day - back),
          _remove(text, match),
        );
      }
    }
    return null;
  }

  (DateTime, String)? _weekdayDay(String text, DateTime today) {
    var match = _weekday.firstMatch(text);
    int? weekday;
    if (match != null) {
      weekday = _weekdayNumbers[match.group(1)!.substring(0, 3).toLowerCase()];
    } else {
      match = _shortWeekday.firstMatch(text);
      if (match != null) {
        weekday =
            _weekdayNumbers[match.group(1)!.substring(0, 3).toLowerCase()];
      }
    }
    if (match == null || weekday == null) return null;

    // The most recent such day, today included.
    final back = (today.weekday - weekday) % 7;
    return (
      DateTime(today.year, today.month, today.day - back),
      _remove(text, match),
    );
  }

  /// A real date, or null for something like 31 February. Without a year, a
  /// date that has not happened yet this year is taken to be last year's.
  DateTime? _build(DateTime today, int day, int month, int? year) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    var y = year ?? today.year;
    var date = DateTime(y, month, day);
    if (date.month != month || date.day != day) return null;
    if (year == null && date.isAfter(today)) {
      y -= 1;
      date = DateTime(y, month, day);
      if (date.month != month || date.day != day) return null;
    }
    return date;
  }

  int _fullYear(String year) =>
      year.length == 2 ? 2000 + int.parse(year) : int.parse(year);

  // ---- amount ----

  (int?, String) _takeAmount(String text) {
    RegExpMatch? best;
    var bestRank = -1;
    var bestAmount = 0;

    for (final match in _amount.allMatches(text)) {
      final amount = _minorOf(match);
      if (amount == null || amount <= 0) continue;
      // A currency word, a "k" or a "/=" says "this is the price".
      final marked =
          match.group(1) != null ||
          match.group(2) != null ||
          match.group(5) != null ||
          match.group(6) != null;
      final rank = marked ? 1 : 0;
      if (rank > bestRank || (rank == bestRank && amount > bestAmount)) {
        best = match;
        bestRank = rank;
        bestAmount = amount;
      }
    }
    if (best == null) return (null, text);
    return (bestAmount, _remove(text, best));
  }

  int? _minorOf(RegExpMatch match) {
    final whole = match.group(3)!.replaceAll(',', '');
    final minor = Money.tryParse('$whole${match.group(4) ?? ''}');
    if (minor == null) return null;
    return match.group(5) != null ? minor * 1000 : minor;
  }

  // ---- words ----

  (String, String) _split(String text) {
    var rest = text.replaceFirst(_leadingFiller, '');
    rest = _tidy(rest);

    final match = _vendorWord.firstMatch(rest);
    if (match == null) return ('', _tidy(rest));

    final before = rest.substring(0, match.start);
    final after = rest.substring(match.end);
    return (_tidy(after), _tidy(before));
  }

  /// Removes the matched text and the spaces it leaves behind.
  String _remove(String text, Match match) =>
      '${text.substring(0, match.start)} ${text.substring(match.end)}';

  String _tidy(String text) => text
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[\s,.\-:;]+|[\s,.\-:;]+$'), '')
      .trim();

  String _titleCase(String text) {
    if (text.isEmpty) return text;
    // Respect capitals the user typed; only fix an all-lowercase name.
    if (text != text.toLowerCase()) return text;
    return text
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _capitalizeFirst(String text) =>
      text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

  DateTime _dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
