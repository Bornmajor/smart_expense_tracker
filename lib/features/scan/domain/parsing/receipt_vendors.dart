/// Finds the shop or business name on a receipt. It is nearly always one of
/// the first lines, so the rest of the receipt is not searched.
abstract final class ReceiptVendors {
  /// How many lines from the top are looked at.
  static const _linesChecked = 8;
  static const _maxLength = 50;

  // Lines at the top of a receipt that are not the name: contact details,
  // addresses, tax numbers and receipt wording.
  static final _notAName = RegExp(
    r'\b(tel|telephone|phone|mobile|fax|p\.?\s?o\.?\s?box|box|street|road|'
    r'avenue|ave|floor|building|plaza|www|http|https|email|e-mail|pin|vat|tin|'
    r'reg|receipt|invoice|tax|welcome|thank|cashier|till|date|time|order|'
    r'table|served|customer|copy|duplicate|total|subtotal|cash|change|amount|'
    r'balance|paid|payment|tendered|qty|quantity)\b|\.com\b|@',
    caseSensitive: false,
  );

  // A decimal amount such as "65.00": an item or total line, not a name.
  static final _hasAmount = RegExp(r'\d[.,]\d{2}\b');

  static final _letters = RegExp(r'[a-zA-Z]');
  static final _digits = RegExp(r'\d');
  static final _edges = RegExp(r'^[^a-zA-Z0-9]+|[^a-zA-Z0-9.)]+$');

  /// The first line that looks like a name, tidied up, or null.
  static String? find(List<String> lines) {
    for (final line in lines.take(_linesChecked)) {
      if (!_looksLikeName(line)) continue;
      final name = _tidy(line);
      if (name.isNotEmpty) return name;
    }
    return null;
  }

  static bool _looksLikeName(String line) {
    final letters = _letters.allMatches(line).length;
    if (letters < 3) return false;

    // Mostly digits: a phone number, a receipt number, a date.
    final digits = _digits.allMatches(line).length;
    if (digits > letters) return false;

    return !_notAName.hasMatch(line) && !_hasAmount.hasMatch(line);
  }

  static String _tidy(String line) {
    var name = line.replaceAll(_edges, '').replaceAll(RegExp(r'\s+'), ' ');

    // ALL CAPS is how most receipts print names; "Shell Petrol Station" reads
    // better in a form.
    if (name == name.toUpperCase()) name = _titleCase(name);

    if (name.length > _maxLength) {
      name = name.substring(0, _maxLength);
      final lastSpace = name.lastIndexOf(' ');
      if (lastSpace > 0) name = name.substring(0, lastSpace);
    }
    return name.trim();
  }

  static String _titleCase(String text) => text
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : word[0].toUpperCase() + word.substring(1).toLowerCase(),
      )
      .join(' ');
}
