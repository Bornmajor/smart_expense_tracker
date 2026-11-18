import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/scan/domain/parsing/receipt_amounts.dart';

void main() {
  int? total(List<String> lines) => ReceiptAmounts.findTotal(lines)?.minor;

  group('a line labelled as the total', () {
    test('reads the amount after the label', () {
      expect(total(['MILK 65.00', 'TOTAL 1,160.00']), 116000);
    });

    test('ignores case and a colon', () {
      expect(total(['total: 45.50']), 4550);
      expect(total(['Total   45.50']), 4550);
    });

    test('accepts a whole number on a labelled line', () {
      expect(total(['TOTAL: KSh 1,500']), 150000);
      expect(total(['TOTAL 300']), 30000);
    });

    test(
      'takes the amount with decimals when the line has several numbers',
      () {
        expect(total(['TOTAL 5 ITEMS 1,200.00']), 120000);
      },
    );

    test('is not marked as a guess', () {
      expect(ReceiptAmounts.findTotal(['TOTAL 10.00'])!.isGuess, isFalse);
    });

    test('reads the amount from the next line when the label stands alone', () {
      expect(total(['GRAND TOTAL', 'KES 5,865.00']), 586500);
      expect(total(['TOTAL', '1,160.00']), 116000);
    });

    test('looks two lines ahead past a lone currency code', () {
      expect(total(['TOTAL', 'KES', '1,160.00']), 116000);
    });

    test('does not borrow an amount that belongs to another label', () {
      final result = ReceiptAmounts.findTotal(['TOTAL', 'CASH 500.00']);

      expect(result, isNull, reason: 'cash is a payment line, not a total');
    });

    test('uses the last total when there are several of the same kind', () {
      expect(total(['TOTAL 100.00', 'TOTAL 250.00']), 25000);
    });

    test('prefers "amount due" over a plain total, wherever it is', () {
      expect(total(['TOTAL 500.00', 'AMOUNT DUE 450.00']), 45000);
      expect(total(['AMOUNT DUE 450.00', 'TOTAL 500.00']), 45000);
    });

    test('knows the other ways receipts name the final amount', () {
      for (final label in [
        'GRAND TOTAL',
        'TOTAL DUE',
        'BALANCE DUE',
        'TOTAL AMOUNT',
        'AMOUNT PAYABLE',
        'NET TOTAL',
        'TO PAY',
      ]) {
        expect(total(['$label 99.00']), 9900, reason: label);
      }
    });

    test('falls back to an "amount" label when there is no total', () {
      expect(total(['AMOUNT 75.00']), 7500);
    });
  });

  group('lines that mention total but are not the total', () {
    test('skips subtotals', () {
      expect(total(['SUBTOTAL 665.00', 'TOTAL 770.00']), 77000);
      expect(total(['SUB TOTAL 665.00', 'TOTAL 770.00']), 77000);
      expect(total(['Sub-total 665.00', 'TOTAL 770.00']), 77000);
    });

    test('skips total tax, discount, items and savings', () {
      for (final label in [
        'TOTAL TAX',
        'TOTAL VAT',
        'TOTAL DISCOUNT',
        'TOTAL ITEMS',
        'TOTAL QTY',
        'TOTAL SAVINGS',
        'TOTAL POINTS',
      ]) {
        expect(total(['TOTAL 770.00', '$label 91.00']), 77000, reason: label);
      }
    });

    test('keeps a total that merely mentions VAT', () {
      expect(total(['TOTAL (incl. VAT) 1,160.00']), 116000);
    });

    test('a zero total is ignored', () {
      expect(total(['TOTAL 0.00']), isNull);
    });
  });

  group('number formats', () {
    test('thousands with commas and decimals with a dot', () {
      expect(total(['TOTAL 1,234.56']), 123456);
      expect(total(['TOTAL 1,234,567.89']), 123456789);
    });

    test('thousands with dots and decimals with a comma', () {
      expect(total(['TOTAL 1.234,56']), 123456);
    });

    test('a comma as the decimal separator', () {
      expect(total(['Total 4,30 EUR']), 430);
      expect(total(['Total 12,5']), 1250);
    });

    test('a single decimal digit', () {
      expect(total(['TOTAL 12.5']), 1250);
    });

    test('a separator followed by three digits groups thousands', () {
      expect(total(['TOTAL 1,234']), 123400);
      expect(total(['TOTAL 1.234.567']), 123456700);
    });

    test('amounts under one', () {
      expect(total(['TOTAL 0.50']), 50);
    });

    test('currency symbols and codes do not matter', () {
      expect(total(['TOTAL \$20.82']), 2082);
      expect(total(['TOTAL €4.30']), 430);
      expect(total(['TOTAL £7.00']), 700);
      expect(total(['TOTAL USD 20.82']), 2082);
    });

    test('ignores things that look like dates', () {
      expect(total(['TOTAL 12.11.2026']), isNull);
    });

    test('ignores numbers too large to be a price', () {
      expect(total(['TOTAL 99999999999.00']), isNull);
    });
  });

  group('without a total label', () {
    test('uses the largest amount with decimals, marked as a guess', () {
      final result = ReceiptAmounts.findTotal([
        'PANADOL 150.00',
        'SYRUP 320.50',
      ]);

      expect(result!.minor, 32050);
      expect(result.isGuess, isTrue);
    });

    test('leaves out cash given and change', () {
      expect(
        total([
          'PANADOL 150.00',
          'SYRUP 320.50',
          'CASH 1,000.00',
          'CHANGE 529.50',
        ]),
        32050,
      );
    });

    test('leaves out card and mobile money lines', () {
      for (final label in ['VISA', 'MASTERCARD', 'CARD', 'MPESA', 'M-PESA']) {
        expect(total(['ITEM 50.00', '$label 500.00']), 5000, reason: label);
      }
    });

    test('ignores whole numbers such as phone numbers and quantities', () {
      expect(total(['TEL 0712345678', 'QTY 12']), isNull);
    });

    test('is null when there are no amounts at all', () {
      expect(total(['HELLO', 'THANK YOU']), isNull);
      expect(total([]), isNull);
    });
  });
}
