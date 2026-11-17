import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/utils/money.dart';

void main() {
  group('Money.tryParse', () {
    test('parses whole and decimal amounts into minor units', () {
      expect(Money.tryParse('12.50'), 1250);
      expect(Money.tryParse('1200'), 120000);
      expect(Money.tryParse('0.05'), 5);
      expect(Money.tryParse('7.5'), 750);
    });

    test('accepts a comma as the decimal separator and ignores spaces', () {
      expect(Money.tryParse('12,5'), 1250);
      expect(Money.tryParse(' 7 '), 700);
    });

    test('returns null for text that is not a valid amount', () {
      for (final input in ['', 'abc', '-5', '1.234', '12.', '.5', '1.2.3']) {
        expect(Money.tryParse(input), isNull, reason: 'input: "$input"');
      }
    });

    test('rejects amounts too large to store safely', () {
      expect(Money.tryParse('1234567890123'), isNull);
    });
  });

  group('Money.format', () {
    test('always shows two decimals', () {
      expect(Money.format(0), '0.00');
      expect(Money.format(5), '0.05');
      expect(Money.format(1250), '12.50');
    });

    test('groups thousands with commas', () {
      expect(Money.format(123456), '1,234.56');
      expect(Money.format(100000000), '1,000,000.00');
    });

    test('keeps the sign for negative amounts', () {
      expect(Money.format(-1250), '-12.50');
    });
  });
}
