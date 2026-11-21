import 'package:equatable/equatable.dart';

import 'money.dart';

/// A currency the user can show amounts in.
///
/// This only changes how amounts are *written*. The number stored for an
/// expense never changes, so switching currency relabels existing amounts and
/// does not convert them. Amounts always have two decimals, because they are
/// stored in hundredths, so a currency such as the Ugandan shilling is shown
/// as 12,000.00.
class Currency extends Equatable {
  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  /// The ISO 4217 code, such as "KES". Empty for [none].
  final String code;

  /// What is written before the amount, such as "KSh" or "$".
  final String symbol;
  final String name;

  /// Amounts shown as plain numbers, as the app did before currencies existed.
  static const none = Currency(code: '', symbol: '', name: 'No symbol');

  static const kes = Currency(
    code: 'KES',
    symbol: 'KSh',
    name: 'Kenyan shilling',
  );
  static const usd = Currency(code: 'USD', symbol: r'$', name: 'US dollar');

  /// Every currency offered in Settings, "No symbol" first, then the rest by
  /// name.
  static const all = <Currency>[
    none,
    Currency(code: 'AUD', symbol: r'A$', name: 'Australian dollar'),
    Currency(code: 'BDT', symbol: '৳', name: 'Bangladeshi taka'),
    Currency(code: 'GBP', symbol: '£', name: 'British pound'),
    Currency(code: 'CAD', symbol: r'CA$', name: 'Canadian dollar'),
    Currency(code: 'CNY', symbol: '¥', name: 'Chinese yuan'),
    Currency(code: 'EGP', symbol: r'E£', name: 'Egyptian pound'),
    Currency(code: 'ETB', symbol: 'Br', name: 'Ethiopian birr'),
    Currency(code: 'EUR', symbol: '€', name: 'Euro'),
    Currency(code: 'GHS', symbol: 'GH₵', name: 'Ghanaian cedi'),
    Currency(code: 'INR', symbol: '₹', name: 'Indian rupee'),
    kes,
    Currency(code: 'MYR', symbol: 'RM', name: 'Malaysian ringgit'),
    Currency(code: 'NGN', symbol: '₦', name: 'Nigerian naira'),
    Currency(code: 'PKR', symbol: 'Rs', name: 'Pakistani rupee'),
    Currency(code: 'PHP', symbol: '₱', name: 'Philippine peso'),
    Currency(code: 'RWF', symbol: 'RWF', name: 'Rwandan franc'),
    Currency(code: 'SGD', symbol: r'S$', name: 'Singapore dollar'),
    Currency(code: 'ZAR', symbol: 'R', name: 'South African rand'),
    Currency(code: 'TZS', symbol: 'TSh', name: 'Tanzanian shilling'),
    Currency(code: 'AED', symbol: 'AED', name: 'UAE dirham'),
    Currency(code: 'UGX', symbol: 'USh', name: 'Ugandan shilling'),
    usd,
  ];

  /// Which currency to start with in each country.
  static const _byRegion = <String, String>{
    'AE': 'AED',
    'AU': 'AUD',
    'BD': 'BDT',
    'CA': 'CAD',
    'CN': 'CNY',
    'EG': 'EGP',
    'ET': 'ETB',
    'GB': 'GBP',
    'GH': 'GHS',
    'IN': 'INR',
    'KE': 'KES',
    'MY': 'MYR',
    'NG': 'NGN',
    'PH': 'PHP',
    'PK': 'PKR',
    'RW': 'RWF',
    'SG': 'SGD',
    'TZ': 'TZS',
    'UG': 'UGX',
    'US': 'USD',
    'ZA': 'ZAR',
    // The euro area.
    'AT': 'EUR',
    'BE': 'EUR',
    'DE': 'EUR',
    'ES': 'EUR',
    'FI': 'EUR',
    'FR': 'EUR',
    'GR': 'EUR',
    'IE': 'EUR',
    'IT': 'EUR',
    'NL': 'EUR',
    'PT': 'EUR',
  };

  /// The currency with this code, or null when it is not offered.
  static Currency? byCode(String? code) {
    for (final currency in all) {
      if (currency.code == code) return currency;
    }
    return null;
  }

  /// The currency to start with for a phone in [countryCode] (such as "KE"),
  /// or [none] when the country is unknown or not in the list.
  static Currency forRegion(String? countryCode) {
    final code = _byRegion[countryCode?.toUpperCase()];
    return byCode(code) ?? none;
  }

  /// How it is listed in Settings: "Kenyan shilling (KES)".
  String get label => code.isEmpty ? name : '$name ($code)';

  /// The amount as shown on screen: "KSh 1,234.56" or "$1,234.56". A symbol
  /// made of letters gets a space after it; one made of signs does not.
  String format(int minorUnits) {
    final sign = minorUnits < 0 ? '-' : '';
    final digits = Money.format(minorUnits.abs());
    if (symbol.isEmpty) return '$sign$digits';

    final hasLetters = RegExp('[A-Za-z]').hasMatch(symbol);
    // A no-break space, so the symbol is never left alone at a line end.
    return hasLetters ? '$sign$symbol $digits' : '$sign$symbol$digits';
  }

  /// The amount for a quick look, on Home and the Summary: whole units when
  /// the amount is $glanceFrom or more, or has no cents anyway ("KSh 28,946",
  /// "KSh 350"), and the exact amount otherwise ("KSh 450.50"). Cents on a big
  /// number are noise at a glance. Lists, forms and exports keep using [format].
  String formatGlance(int minorUnits) {
    final exact = minorUnits.abs() < glanceFrom && minorUnits % 100 != 0;
    if (exact) return format(minorUnits);
    final sign = minorUnits < 0 ? '-' : '';
    final digits = Money.formatWhole(minorUnits.abs());
    if (symbol.isEmpty) return '$sign$digits';
    final hasLetters = RegExp('[A-Za-z]').hasMatch(symbol);
    // A no-break space, as in [format], so the symbol is never left alone at a
    // line end.
    return hasLetters ? '$sign$symbol $digits' : '$sign$symbol$digits';
  }

  /// From this amount up (1,000.00), glance numbers drop the cents.
  static const glanceFrom = 100000;

  /// The amount with the code, for places that may lack the symbol's glyph,
  /// such as a PDF: "KES 1,234.56".
  String formatWithCode(int minorUnits) {
    final digits = Money.format(minorUnits);
    return code.isEmpty ? digits : '$code $digits';
  }

  @override
  List<Object?> get props => [code, symbol, name];
}
