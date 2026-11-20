import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/utils/currency.dart';

void main() {
  group('format', () {
    test('puts a letter symbol before the amount with a no-break space', () {
      expect(Currency.kes.format(123456), 'KSh 1,234.56');
    });

    test('puts a sign symbol directly before the amount', () {
      expect(Currency.usd.format(123456), r'$1,234.56');
      expect(Currency.byCode('EUR')!.format(5), '€0.05');
      expect(Currency.byCode('NGN')!.format(250000), '₦2,500.00');
    });

    test('a symbol that mixes letters and a sign gets the space', () {
      expect(Currency.byCode('GHS')!.format(1050), 'GH₵ 10.50');
    });

    test('writes plain numbers for "No symbol"', () {
      expect(Currency.none.format(123456), '1,234.56');
    });

    test('puts the minus sign before the symbol', () {
      expect(Currency.usd.format(-250), r'-$2.50');
      expect(Currency.kes.format(-250), '-KSh 2.50');
      expect(Currency.none.format(-250), '-2.50');
    });

    test('always shows two decimals, even for shillings', () {
      expect(Currency.byCode('UGX')!.format(1200000), 'USh 12,000.00');
    });

    test('shows zero', () {
      expect(Currency.usd.format(0), r'$0.00');
    });
  });

  group('formatWithCode', () {
    test('puts the code before the amount', () {
      expect(Currency.kes.formatWithCode(123456), 'KES 1,234.56');
    });

    test('is the plain amount for "No symbol"', () {
      expect(Currency.none.formatWithCode(123456), '1,234.56');
    });

    test('keeps a minus sign', () {
      expect(Currency.usd.formatWithCode(-250), 'USD -2.50');
    });
  });

  group('byCode', () {
    test('finds a currency by its code', () {
      expect(Currency.byCode('KES'), Currency.kes);
    });

    test('finds "No symbol" by its empty code', () {
      expect(Currency.byCode(''), Currency.none);
    });

    test('is null for a code that is not offered', () {
      expect(Currency.byCode('XYZ'), isNull);
      expect(Currency.byCode(null), isNull);
    });
  });

  group('forRegion', () {
    test("starts with the currency of the phone's country", () {
      expect(Currency.forRegion('KE'), Currency.kes);
      expect(Currency.forRegion('US'), Currency.usd);
      expect(Currency.forRegion('NG').code, 'NGN');
    });

    test('ignores the case of the country code', () {
      expect(Currency.forRegion('ke'), Currency.kes);
    });

    test('uses the euro across the euro area', () {
      for (final country in ['DE', 'FR', 'IE', 'IT', 'NL']) {
        expect(Currency.forRegion(country).code, 'EUR', reason: country);
      }
    });

    test('is "No symbol" for an unknown or missing country', () {
      expect(Currency.forRegion('ZZ'), Currency.none);
      expect(Currency.forRegion(null), Currency.none);
      expect(Currency.forRegion(''), Currency.none);
    });
  });

  group('the list', () {
    test('starts with "No symbol", then goes by name', () {
      expect(Currency.all.first, Currency.none);

      final names = Currency.all
          .skip(1)
          .map((c) => c.name.toLowerCase())
          .toList();
      expect(names, [...names]..sort());
    });

    test('has no code twice', () {
      final codes = Currency.all.map((c) => c.code).toList();

      expect(codes.toSet(), hasLength(codes.length));
    });

    test('gives every real currency a code and a symbol', () {
      for (final currency in Currency.all.skip(1)) {
        expect(currency.code, hasLength(3), reason: currency.name);
        expect(currency.symbol, isNotEmpty, reason: currency.name);
      }
    });

    test('starts every country in the table with a currency in the list', () {
      // forRegion falls back to "No symbol" for a code that is not listed, so
      // a typo in the table would show up here.
      for (final country in ['KE', 'UG', 'TZ', 'RW', 'NG', 'GH', 'ZA', 'US']) {
        expect(Currency.forRegion(country), isNot(Currency.none));
      }
    });

    test('labels a currency with its name and code', () {
      expect(Currency.kes.label, 'Kenyan shilling (KES)');
      expect(Currency.none.label, 'No symbol');
    });
  });
}
