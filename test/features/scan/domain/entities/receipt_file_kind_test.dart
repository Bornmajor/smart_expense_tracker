import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/receipt_file_kind.dart';

List<int> bytes(String text) => text.codeUnits;

void main() {
  group('ReceiptFileKind.detect', () {
    test('recognises a PDF', () {
      expect(
        ReceiptFileKind.detect(bytes('%PDF-1.7\n...')),
        ReceiptFileKind.pdf,
      );
    });

    test('recognises a PDF with junk before the header', () {
      expect(
        ReceiptFileKind.detect(bytes('\n\n  %PDF-1.4')),
        ReceiptFileKind.pdf,
      );
    });

    test('recognises a JPEG', () {
      expect(
        ReceiptFileKind.detect([0xFF, 0xD8, 0xFF, 0xE0, 0, 0]),
        ReceiptFileKind.image,
      );
    });

    test('recognises a PNG', () {
      expect(
        ReceiptFileKind.detect([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
        ]),
        ReceiptFileKind.image,
      );
    });

    test('recognises a WEBP', () {
      expect(
        ReceiptFileKind.detect(bytes('RIFF1234WEBPVP8 ')),
        ReceiptFileKind.image,
      );
    });

    test('recognises a HEIC photo', () {
      final head = [0, 0, 0, 24, ...bytes('ftypheic'), 0, 0, 0, 0];
      expect(ReceiptFileKind.detect(head), ReceiptFileKind.image);
    });

    test('does not call a text or Word file a receipt', () {
      expect(
        ReceiptFileKind.detect(bytes('hello world')),
        ReceiptFileKind.unknown,
      );
      expect(
        ReceiptFileKind.detect([0x50, 0x4B, 0x03, 0x04, 0, 0]),
        ReceiptFileKind.unknown,
      );
    });

    test('an empty file is unknown', () {
      expect(ReceiptFileKind.detect(const []), ReceiptFileKind.unknown);
    });
  });
}
