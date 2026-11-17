/// Money helpers. Amounts are stored as integer minor units (cents).
abstract final class Money {
  static final _amountPattern = RegExp(r'^(\d{1,12})(?:\.(\d{1,2}))?$');

  /// Parses text such as "12.50", "12,5" or "1200" into minor units.
  /// Returns null when the text is not a valid non-negative amount.
  static int? tryParse(String input) {
    final text = input.trim().replaceAll(',', '.');
    final match = _amountPattern.firstMatch(text);
    if (match == null) return null;

    final whole = int.parse(match.group(1)!);
    final cents = int.parse((match.group(2) ?? '').padRight(2, '0'));
    return whole * 100 + cents;
  }

  /// Formats minor units as "1,234.56".
  static String format(int minorUnits) {
    final negative = minorUnits < 0;
    final abs = minorUnits.abs();
    final whole = (abs ~/ 100).toString();
    final cents = (abs % 100).toString().padLeft(2, '0');

    final grouped = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
      grouped.write(whole[i]);
    }
    return '${negative ? '-' : ''}$grouped.$cents';
  }
}
