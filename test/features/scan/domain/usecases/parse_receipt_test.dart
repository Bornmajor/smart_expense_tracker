import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/receipt_draft.dart';
import 'package:smart_expense_tracker/features/scan/domain/usecases/parse_receipt.dart';

/// Whole receipts as OCR would hand them over, top to bottom.
void main() {
  // "Today": 18 November 2026.
  final parseReceipt = ParseReceipt(now: () => DateTime(2026, 11, 18, 9));

  group('ParseReceipt on whole receipts', () {
    test('a supermarket receipt', () {
      final draft = parseReceipt([
        'NAIVAS SUPERMARKET',
        'WESTLANDS BRANCH',
        'P.O BOX 1234 NAIROBI',
        'TEL: 0712 345 678',
        'PIN: P051234567X',
        'Date: 16/11/2026 14:35',
        'Receipt No: 004521',
        'MILK 500ML 2 x 65.00 130.00',
        'BREAD 55.00',
        'EGGS TRAY 480.00',
        'SUBTOTAL 665.00',
        'VAT 16% 91.72',
        'TOTAL 665.00',
        'CASH 1,000.00',
        'CHANGE 335.00',
        'THANK YOU FOR SHOPPING',
      ]);

      expect(
        draft,
        ReceiptDraft(
          vendor: 'Naivas Supermarket',
          date: DateTime(2026, 11, 16),
          totalMinor: 66500,
        ),
      );
    });

    test('a petrol station receipt with the total on its own line', () {
      final draft = parseReceipt([
        'SHELL PETROL STATION',
        'Waiyaki Way',
        '16-11-2026 08:12',
        'UNLEADED 30.00 L @ 195.50',
        'GRAND TOTAL',
        'KES 5,865.00',
        'PAID BY CARD',
      ]);

      expect(draft.vendor, 'Shell Petrol Station');
      expect(draft.date, DateTime(2026, 11, 16));
      expect(draft.totalMinor, 586500);
      expect(draft.totalIsGuess, isFalse);
    });

    test('a US diner receipt with a month-first date, tax and tip', () {
      final draft = parseReceipt([
        "Joe's Diner",
        '123 Main Street',
        'Nov 16, 2026  7:45 PM',
        'Table 12',
        'Burger 12.50',
        'Fries 4.00',
        'Subtotal 16.50',
        'Tax 1.32',
        'Tip 3.00',
        r'Total Due $20.82',
      ]);

      expect(draft.vendor, "Joe's Diner");
      expect(draft.date, DateTime(2026, 11, 16));
      expect(draft.totalMinor, 2082);
    });

    test('a European receipt with comma decimals and a dotted date', () {
      final draft = parseReceipt([
        'Bäckerei Müller',
        '16.11.2026',
        'Brötchen 3 x 0,60 1,80',
        'Kaffee 2,50',
        'Total 4,30 EUR',
      ]);

      expect(draft.vendor, 'Bäckerei Müller');
      expect(draft.date, DateTime(2026, 11, 16));
      expect(draft.totalMinor, 430);
    });

    test(
      'a pharmacy receipt with no total label guesses the largest amount',
      () {
        final draft = parseReceipt([
          'CITY PHARMACY',
          'Tel 020 123 4567',
          '16/11/26',
          'PANADOL 24S 150.00',
          'COUGH SYRUP 320.50',
          'CASH 500.00',
          'CHANGE 29.50',
        ]);

        expect(draft.vendor, 'City Pharmacy');
        expect(draft.date, DateTime(2026, 11, 16));
        expect(draft.totalMinor, 32050);
        expect(draft.totalIsGuess, isTrue);
      },
    );
  });

  group('ParseReceipt with a poor read', () {
    test('a smudged date still gives the vendor and the total', () {
      final draft = parseReceipt([
        'Corner Cafe',
        'Dat: 1?/1?/2O26',
        'TOTAL 8.50',
      ]);

      expect(draft.vendor, 'Corner Cafe');
      expect(draft.date, isNull);
      expect(draft.totalMinor, 850);
    });

    test('a missing total still gives the vendor and the date', () {
      final draft = parseReceipt(['Corner Cafe', '16/11/2026']);

      expect(draft.vendor, 'Corner Cafe');
      expect(draft.date, DateTime(2026, 11, 16));
      expect(draft.totalMinor, isNull);
      expect(draft.totalIsGuess, isFalse);
    });

    test('text with nothing useful gives an empty draft', () {
      final draft = parseReceipt(['~~~', '...', '12']);

      expect(draft.isEmpty, isTrue);
    });

    test('no text at all gives an empty draft', () {
      expect(parseReceipt([]).isEmpty, isTrue);
      expect(parseReceipt(['', '   ']).isEmpty, isTrue);
    });
  });

  group('ParseReceipt input handling', () {
    test('ignores blank lines and surrounding spaces', () {
      final draft = parseReceipt([
        '',
        '  Corner Cafe  ',
        '',
        '  16/11/2026 ',
        '   ',
        ' TOTAL ',
        '',
        ' 8.50 ',
      ]);

      expect(draft.vendor, 'Corner Cafe');
      expect(draft.date, DateTime(2026, 11, 16));
      expect(draft.totalMinor, 850, reason: 'label and amount were apart');
    });

    test('decides what is "today" from the clock it is given', () {
      final early = ParseReceipt(now: () => DateTime(2026, 11, 10));

      expect(early(['16/11/2026']).date, isNull, reason: 'in its future');
    });

    test('uses the real clock by default', () {
      final draft = ParseReceipt()(['2020-01-15', 'TOTAL 1.00']);

      expect(draft.date, DateTime(2020, 1, 15));
    });
  });

  group('ReceiptDraft', () {
    test('is empty only when nothing was found', () {
      expect(const ReceiptDraft().isEmpty, isTrue);
      expect(const ReceiptDraft(vendor: 'A').isEmpty, isFalse);
      expect(ReceiptDraft(date: DateTime(2026)).isEmpty, isFalse);
      expect(const ReceiptDraft(totalMinor: 1).isEmpty, isFalse);
    });
  });
}
