import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/currency_conversion/domain/entities/exchange_rates.dart';
import 'package:smart_expense_tracker/features/currency_conversion/domain/usecases/convert_amount.dart';

void main() {
  final rates = ExchangeRates(
    perUsd: const {'USD': 1, 'KES': 129, 'EUR': 0.92, 'UGX': 3700},
    fetchedAt: DateTime(2026, 11, 21),
  );

  int? convert(int minor, String from, String to) =>
      ConvertAmount.call(minor: minor, from: from, to: to, rates: rates);

  group('ConvertAmount', () {
    test('converts dollars to shillings', () {
      expect(convert(10000, 'USD', 'KES'), 1290000);
    });

    test('converts between two other currencies through the dollar', () {
      // 100.00 EUR = 108.70 USD = 14,021.74 KES
      expect(convert(10000, 'EUR', 'KES'), 1402174);
    });

    test('rounds to the nearest minor unit', () {
      expect(convert(1, 'USD', 'KES'), 129);
      expect(convert(1, 'KES', 'USD'), 0);
      expect(convert(100, 'KES', 'USD'), 1);
    });

    test('the same currency is unchanged', () {
      expect(convert(12345, 'KES', 'KES'), 12345);
    });

    test('is null when a currency has no rate', () {
      expect(convert(100, 'USD', 'XYZ'), isNull);
      expect(convert(100, 'XYZ', 'KES'), isNull);
    });

    test('is null for a negative amount', () {
      expect(convert(-1, 'USD', 'KES'), isNull);
    });
  });

  group('ExchangeRates', () {
    test('says when it is older than an age', () {
      final now = DateTime(2026, 11, 30);

      expect(rates.isOlderThan(const Duration(days: 7), now), isTrue);
      expect(rates.isOlderThan(const Duration(days: 10), now), isFalse);
    });

    test('a zero or missing rate counts as no rate', () {
      final bad = ExchangeRates(
        perUsd: const {'USD': 1, 'XXX': 0},
        fetchedAt: DateTime(2026),
      );

      expect(bad.has('XXX'), isFalse);
      expect(bad.has('ZZZ'), isFalse);
      expect(bad.has('USD'), isTrue);
    });
  });
}
