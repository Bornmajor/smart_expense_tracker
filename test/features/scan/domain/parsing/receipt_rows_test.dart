import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/ocr_line.dart';
import 'package:smart_expense_tracker/features/scan/domain/parsing/receipt_rows.dart';
import 'package:smart_expense_tracker/features/scan/domain/usecases/parse_receipt.dart';

/// A line of text as OCR reports it: where it starts (left), how far down the
/// photo it is (top), and how tall it is. Width does not matter to the rows.
OcrLine line(
  String text, {
  double left = 0,
  double top = 0,
  double height = 20,
}) => OcrLine(
  text: text,
  left: left,
  top: top,
  right: left + 100,
  bottom: top + height,
);

void main() {
  group('why rows are rebuilt', () {
    // A two-column receipt. OCR reads the whole left column (names) as one
    // group and the whole right column (prices) as another, so the label
    // "TOTAL" and its amount end up far apart in the list.
    final ocrOrder = [
      line('CORNER CAFE', left: 20, top: 10),
      line('MILK', left: 20, top: 60),
      line('BREAD', left: 20, top: 90),
      line('TOTAL', left: 20, top: 130),
      line('65.00', left: 300, top: 60),
      line('55.00', left: 300, top: 90),
      line('120.00', left: 300, top: 130),
    ];

    test('without rebuilding, the total label is far from its amount', () {
      final plainLines = [for (final l in ocrOrder) l.text];

      expect(plainLines, [
        'CORNER CAFE',
        'MILK',
        'BREAD',
        'TOTAL',
        '65.00',
        '55.00',
        '120.00',
      ]);
    });

    test('with rebuilding, each label sits next to its amount', () {
      expect(ReceiptRows.build(ocrOrder), [
        'CORNER CAFE',
        'MILK 65.00',
        'BREAD 55.00',
        'TOTAL 120.00',
      ]);
    });

    test('so the parser finds the total from the rebuilt rows', () {
      final parse = ParseReceipt(now: () => DateTime(2026, 11, 18));

      final draft = parse(ReceiptRows.build(ocrOrder));

      expect(draft.vendor, 'Corner Cafe');
      expect(draft.totalMinor, 12000);
      expect(draft.totalIsGuess, isFalse);
    });
  });

  group('ReceiptRows.build', () {
    test('joins lines at the same height, left to right', () {
      expect(
        ReceiptRows.build([
          line('1,160.00', left: 300, top: 50),
          line('TOTAL', left: 20, top: 50),
        ]),
        ['TOTAL 1,160.00'],
        reason: 'the input order does not matter',
      );
    });

    test('joins three pieces in one row: quantity, name and price', () {
      expect(
        ReceiptRows.build([
          line('2', left: 10, top: 40),
          line('MILK 500ML', left: 60, top: 40),
          line('130.00', left: 300, top: 40),
        ]),
        ['2 MILK 500ML 130.00'],
      );
    });

    test('keeps lines at different heights as separate rows', () {
      expect(
        ReceiptRows.build([
          line('MILK', left: 20, top: 40),
          line('BREAD', left: 20, top: 80),
        ]),
        ['MILK', 'BREAD'],
      );
    });

    test('puts rows in order from the top of the photo to the bottom', () {
      expect(
        ReceiptRows.build([
          line('THIRD', top: 120),
          line('FIRST', top: 10),
          line('SECOND', top: 60),
        ]),
        ['FIRST', 'SECOND', 'THIRD'],
      );
    });

    test('still joins lines that are a little out of line with each other', () {
      // Photos are never perfectly straight: the price sits 4 pixels lower.
      expect(
        ReceiptRows.build([
          line('TOTAL', left: 20, top: 100),
          line('99.00', left: 300, top: 104),
        ]),
        ['TOTAL 99.00'],
      );
    });

    test('does not join lines that are clearly on different rows', () {
      // Centres 14 apart on 20-high lines (0.7 of a height): a new row.
      expect(
        ReceiptRows.build([
          line('TOTAL', left: 20, top: 100),
          line('99.00', left: 300, top: 114),
        ]),
        ['TOTAL', '99.00'],
      );
    });

    test('joins at the tolerance and not beyond it', () {
      // 0.5 of a height apart: same row. 0.7 of a height apart: not.
      expect(
        ReceiptRows.build([
          line('A', left: 0, top: 100),
          line('B', left: 200, top: 110),
        ]),
        ['A B'],
      );
      expect(
        ReceiptRows.build([
          line('A', left: 0, top: 100),
          line('B', left: 200, top: 114),
        ]),
        ['A', 'B'],
      );
    });

    test('measures against the smaller line when the heights differ', () {
      // A tall heading and a small price whose centres are 9 apart: against
      // the small line (10 high) that is 0.9 of a height, so separate rows.
      expect(
        ReceiptRows.build([
          line('BIG HEADING', top: 100, height: 40),
          line('1.00', left: 300, top: 129, height: 10),
        ]),
        ['BIG HEADING', '1.00'],
      );
    });

    test('trims the text of each piece', () {
      expect(
        ReceiptRows.build([
          line('  TOTAL  ', left: 20, top: 50),
          line(' 5.00 ', left: 300, top: 50),
        ]),
        ['TOTAL 5.00'],
      );
    });

    test('ignores blank lines and lines with no height', () {
      expect(
        ReceiptRows.build([
          line('   ', top: 10),
          line('', top: 40),
          line('GHOST', top: 70, height: 0),
          line('REAL', top: 100),
        ]),
        ['REAL'],
      );
    });

    test('returns no rows for no lines', () {
      expect(ReceiptRows.build([]), isEmpty);
    });

    test('a single line is a single row', () {
      expect(ReceiptRows.build([line('ONLY', top: 5)]), ['ONLY']);
    });

    test('does not change the list it was given', () {
      final input = [line('B', top: 80), line('A', top: 10)];

      ReceiptRows.build(input);

      expect(input.map((l) => l.text), ['B', 'A']);
    });
  });

  group('OcrLine', () {
    test('knows its height and the middle of its height', () {
      final l = line('X', top: 100, height: 30);

      expect(l.height, 30);
      expect(l.centerY, 115);
    });
  });
}
