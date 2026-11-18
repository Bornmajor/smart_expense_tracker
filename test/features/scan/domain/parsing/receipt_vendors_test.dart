import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/scan/domain/parsing/receipt_vendors.dart';

void main() {
  String? find(List<String> lines) => ReceiptVendors.find(lines);

  group('ReceiptVendors.find', () {
    test('takes the first line that looks like a name', () {
      expect(find(['Corner Cafe', '16/11/2026', 'TOTAL 5.00']), 'Corner Cafe');
    });

    test('keeps the capitals of a mixed-case name', () {
      expect(find(["Joe's Diner"]), "Joe's Diner");
    });

    test('turns an ALL CAPS name into title case', () {
      expect(find(['SHELL PETROL STATION']), 'Shell Petrol Station');
      expect(find(["MCDONALD'S"]), "Mcdonald's");
    });

    test('removes decoration around the name', () {
      expect(find(['*** NAIVAS ***']), 'Naivas');
      expect(find(['--- Corner Cafe ---']), 'Corner Cafe');
      expect(find(['#  Corner   Cafe  ']), 'Corner Cafe');
    });

    test('keeps a full stop or bracket at the end of the name', () {
      expect(find(['Fresh Foods Ltd.']), 'Fresh Foods Ltd.');
      expect(find(['Corner Cafe (Westlands)']), 'Corner Cafe (Westlands)');
    });

    test('handles accented letters', () {
      expect(find(['Bäckerei Müller']), 'Bäckerei Müller');
    });

    test('skips receipt wording and tax details above the name', () {
      expect(
        find(['*** RECEIPT ***', 'TAX INVOICE', 'Corner Cafe']),
        'Corner Cafe',
      );
    });

    test('skips phone numbers, addresses and web addresses', () {
      expect(
        find([
          'TEL 0712345678',
          '0712 345 678',
          'P.O BOX 1234 NAIROBI',
          'www.cornercafe.co.ke',
          'info@cornercafe.com',
          'PIN: P051234567X',
          'Corner Cafe',
        ]),
        'Corner Cafe',
      );
    });

    test('skips lines that are mostly digits', () {
      expect(find(['No 004521 17', 'Corner Cafe']), 'Corner Cafe');
    });

    test('skips dates, times and totals', () {
      expect(find(['16/11/2026', '14:35', 'TOTAL 5.00']), isNull);
    });

    test('never takes an item, total or payment line as the name', () {
      expect(
        find([
          'MILK 65.00',
          'SUBTOTAL 665.00',
          'TOTAL 665.00',
          'CASH 1,000.00',
          'CHANGE 335.00',
          'BALANCE DUE',
          'AMOUNT PAID',
        ]),
        isNull,
      );
    });

    test('needs at least three letters', () {
      expect(find(['A1', 'ab']), isNull);
    });

    test('only looks near the top of the receipt', () {
      final lines = [for (var i = 0; i < 8; i++) '12345 $i', 'Corner Cafe'];

      expect(find(lines), isNull);
    });

    test('shortens a very long name at a word boundary', () {
      final name = find([
        'The Extraordinarily Long Named Restaurant And Grill House Limited',
      ]);

      expect(name!.length, lessThanOrEqualTo(50));
      expect(name, startsWith('The Extraordinarily'));
      expect(name, isNot(endsWith(' ')));
    });

    test('is null for no text', () {
      expect(find([]), isNull);
    });
  });
}
