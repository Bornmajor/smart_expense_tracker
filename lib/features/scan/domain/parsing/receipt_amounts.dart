/// The total found on a receipt.
class ReceiptTotal {
  const ReceiptTotal(this.minor, {required this.isGuess});

  /// Minor units (cents).
  final int minor;

  /// True when it is only the largest amount, not a line labelled "total".
  final bool isGuess;
}

/// Finds the total on a receipt from its text lines.
abstract final class ReceiptAmounts {
  // Longest first: "grand total" and "total due" beat a plain "total".
  static final _strongTotal = RegExp(
    r'\b(grand\s*total|total\s*due|amount\s*due|balance\s*due|total\s*amount|'
    r'amount\s*payable|total\s*payable|net\s*total|total\s*to\s*pay|to\s*pay)\b',
    caseSensitive: false,
  );
  static final _total = RegExp(r'\btotal\b', caseSensitive: false);
  static final _weakTotal = RegExp(r'\bamount\b', caseSensitive: false);

  // Lines that mention "total" but are not the final total.
  static final _notTheTotal = RegExp(
    r'\b(sub\s*-?\s*total|'
    r'total\s+(tax|vat|discount|saving|savings|items?|qty|quantity|points|'
    r'saved|before)|items?\s+total)\b',
    caseSensitive: false,
  );

  // Lines about how it was paid, never the total itself.
  static final _payment = RegExp(
    r'\b(cash|change|tender|tendered|paid|payment|card|visa|mastercard|'
    r'mpesa|m-pesa|tip|balance)\b',
    caseSensitive: false,
  );

  static final _number = RegExp(r'\d[\d.,]*\d|\d');
  static final _letters = RegExp(r'[a-zA-Z]');

  // Words that may sit next to a lone amount without making it a label.
  static final _currency = RegExp(
    r'\b(kes|ksh|kshs|usd|eur|gbp|ugx|tzs|zar|ngn|inr|rs)\b',
    caseSensitive: false,
  );

  /// The total, or null when no amount could be found.
  static ReceiptTotal? findTotal(List<String> lines) {
    final labelled = _labelledTotal(lines);
    if (labelled != null) return ReceiptTotal(labelled, isGuess: false);

    final largest = _largestAmount(lines);
    return largest == null ? null : ReceiptTotal(largest, isGuess: true);
  }

  /// A line like "TOTAL 1,160.00", or "TOTAL" with the amount on the next
  /// line. The strongest label wins; among equals, the one nearest the bottom.
  static int? _labelledTotal(List<String> lines) {
    int? best;
    var bestRank = 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_notTheTotal.hasMatch(line)) continue;

      final rank = _strongTotal.hasMatch(line)
          ? 3
          : _total.hasMatch(line)
          ? 2
          : _weakTotal.hasMatch(line)
          ? 1
          : 0;
      if (rank == 0 || rank < bestRank) continue;

      final minor = _amountOn(line) ?? _amountOnFollowingLine(lines, i);
      if (minor == null) continue;

      best = minor;
      bestRank = rank;
    }
    return best;
  }

  /// The label and the amount are often read as two lines. Looks at the next
  /// two lines for one that holds only an amount.
  static int? _amountOnFollowingLine(List<String> lines, int index) {
    for (var j = index + 1; j < lines.length && j <= index + 2; j++) {
      final next = lines[j];
      final withoutCurrency = next.replaceAll(_currency, '');
      if (_letters.hasMatch(withoutCurrency)) return null;
      final minor = _amountOn(next);
      if (minor != null) return minor;
    }
    return null;
  }

  /// Without any "total" label: the largest amount that has decimals, leaving
  /// out payment lines (cash given, change). Whole numbers are ignored here,
  /// because they are more likely phone numbers, dates and quantities.
  static int? _largestAmount(List<String> lines) {
    int? largest;
    for (final line in lines) {
      if (_payment.hasMatch(line)) continue;
      for (final amount in _amountsIn(line)) {
        if (!amount.hasDecimals) continue;
        if (largest == null || amount.minor > largest) largest = amount.minor;
      }
    }
    return largest;
  }

  /// The amount on a labelled line: the last one with decimals, otherwise the
  /// last one. "TOTAL 5 ITEMS 1,200.00" gives 1,200.00.
  static int? _amountOn(String line) {
    final amounts = _amountsIn(line);
    if (amounts.isEmpty) return null;
    final withDecimals = amounts.where((a) => a.hasDecimals);
    return (withDecimals.isNotEmpty ? withDecimals.last : amounts.last).minor;
  }

  static List<_Amount> _amountsIn(String line) => [
    for (final match in _number.allMatches(line)) ?_parse(match.group(0)!),
  ];

  /// Reads "1,234.56", "1.234,56", "12,50", "1234" and "1,234" as minor units.
  /// Returns null for anything else, such as a date like "12.11.2026".
  static _Amount? _parse(String token) {
    final parts = token.split(RegExp(r'[.,]'));
    if (parts.any((p) => p.isEmpty)) return null;

    bool groupsOk(List<String> groups) =>
        groups.first.length <= 3 && groups.skip(1).every((p) => p.length == 3);

    String whole;
    var cents = 0;
    var hasDecimals = false;

    if (parts.length == 1) {
      whole = parts.first;
    } else if (parts.last.length == 3 && groupsOk(parts)) {
      // "1,234" or "1.234.567": the separator groups thousands.
      whole = parts.join();
    } else if (parts.last.length <= 2 &&
        groupsOk(parts.sublist(0, parts.length - 1))) {
      // "12.50", "12,5" or "1,234.56": the last separator is the decimal.
      whole = parts.sublist(0, parts.length - 1).join();
      cents = int.parse(parts.last.padRight(2, '0'));
      hasDecimals = true;
    } else {
      return null;
    }

    if (whole.length > 10) return null;
    final minor = int.parse(whole) * 100 + cents;
    return minor > 0 ? _Amount(minor, hasDecimals: hasDecimals) : null;
  }
}

class _Amount {
  const _Amount(this.minor, {required this.hasDecimals});

  final int minor;
  final bool hasDecimals;
}
