import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/features/scan/data/repositories/ml_kit_receipt_text_reader.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/ocr_line.dart';
import 'package:smart_expense_tracker/features/scan/domain/parsing/receipt_rows.dart';
import 'package:smart_expense_tracker/features/scan/domain/repositories/receipt_text_reader.dart';
import 'package:smart_expense_tracker/features/scan/domain/scan_exception.dart';
import 'package:smart_expense_tracker/features/scan/domain/usecases/parse_receipt.dart';

// ML Kit's result classes can be built by hand, so a test can make the same
// kind of answer the real recognizer gives, without a phone or a photo.

TextLine textLine(String text, Rect box) => TextLine(
  text: text,
  elements: const [],
  boundingBox: box,
  recognizedLanguages: const [],
  cornerPoints: const [],
  confidence: null,
  angle: null,
);

TextBlock textBlock(List<TextLine> lines) => TextBlock(
  text: lines.map((l) => l.text).join('\n'),
  lines: lines,
  boundingBox: Rect.zero,
  recognizedLanguages: const [],
  cornerPoints: const [],
);

RecognizedText recognized(List<TextBlock> blocks) =>
    RecognizedText(text: blocks.map((b) => b.text).join('\n'), blocks: blocks);

void main() {
  group('MlKitReceiptTextReader.linesFrom', () {
    test('keeps each line\'s text and where it sits', () {
      final lines = MlKitReceiptTextReader.linesFrom(
        recognized([
          textBlock([
            textLine('TOTAL', const Rect.fromLTRB(20, 150, 120, 170)),
          ]),
        ]),
      );

      expect(lines, const [
        OcrLine(text: 'TOTAL', left: 20, top: 150, right: 120, bottom: 170),
      ]);
    });

    test('flattens the lines of every block, in order', () {
      final lines = MlKitReceiptTextReader.linesFrom(
        recognized([
          textBlock([
            textLine('A', const Rect.fromLTRB(0, 0, 10, 10)),
            textLine('B', const Rect.fromLTRB(0, 20, 10, 30)),
          ]),
          textBlock([textLine('C', const Rect.fromLTRB(0, 40, 10, 50))]),
        ]),
      );

      expect(lines.map((l) => l.text), ['A', 'B', 'C']);
    });

    test('gives nothing for a photo with no text', () {
      expect(MlKitReceiptTextReader.linesFrom(recognized([])), isEmpty);
    });

    test('gives nothing for a block that has no lines', () {
      expect(
        MlKitReceiptTextReader.linesFrom(recognized([textBlock([])])),
        isEmpty,
      );
    });
  });

  group('MlKitReceiptTextReader.read', () {
    test('reads the photo it is given and returns its lines', () async {
      String? readPath;
      final reader = MlKitReceiptTextReader(
        recognize: (path) async {
          readPath = path;
          return recognized([
            textBlock([textLine('HELLO', const Rect.fromLTRB(1, 2, 3, 4))]),
          ]);
        },
      );

      final lines = await reader.read('/tmp/receipt.jpg');

      expect(readPath, '/tmp/receipt.jpg');
      expect(lines.single.text, 'HELLO');
    });

    test(
      'turns a recognizer failure into an unreadable-photo problem',
      () async {
        final boom = Exception('model not available');
        final reader = MlKitReceiptTextReader(
          recognize: (_) async => throw boom,
        );

        try {
          await reader.read('/tmp/receipt.jpg');
          fail('expected a ScanException');
        } on ScanException catch (e) {
          expect(e.problem, ScanProblem.unreadable);
          expect(e.cause, same(boom));
        }
      },
    );

    test('can be created without a recognizer, using ML Kit', () {
      // Creating it does not call ML Kit. Only reading a photo does.
      expect(MlKitReceiptTextReader(), isA<ReceiptTextReader>());
    });
  });

  group('the whole chain, minus the phone', () {
    test('a two-block ML Kit result becomes a receipt with a total', () async {
      // ML Kit often reports the left column and the right column of a receipt
      // as two separate blocks, so TOTAL and its amount are far apart.
      final reader = MlKitReceiptTextReader(
        recognize: (_) async => recognized([
          textBlock([
            textLine('CORNER CAFE', const Rect.fromLTRB(20, 10, 160, 30)),
            textLine('COFFEE', const Rect.fromLTRB(20, 60, 100, 80)),
            textLine('TOTAL', const Rect.fromLTRB(20, 100, 90, 120)),
          ]),
          textBlock([
            textLine('3.50', const Rect.fromLTRB(300, 60, 360, 80)),
            textLine('3.50', const Rect.fromLTRB(300, 100, 360, 120)),
          ]),
        ]),
      );

      final rows = ReceiptRows.build(await reader.read('/tmp/receipt.jpg'));
      final draft = ParseReceipt(now: () => DateTime(2026, 11, 18))(rows);

      expect(rows, ['CORNER CAFE', 'COFFEE 3.50', 'TOTAL 3.50']);
      expect(draft.vendor, 'Corner Cafe');
      expect(draft.totalMinor, 350);
    });
  });
}
