import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/ocr_line.dart';
import '../../domain/repositories/receipt_text_reader.dart';
import '../../domain/scan_exception.dart';
import '../datasources/ml_kit_recognizer.dart';

/// Reads receipt text with Google's ML Kit. Everything runs on the device, so
/// no photo or text leaves the phone.
class MlKitReceiptTextReader implements ReceiptTextReader {
  MlKitReceiptTextReader({
    Future<RecognizedText> Function(String photoPath)? recognize,
  }) : _recognize = recognize ?? recognizeWithMlKit;

  final Future<RecognizedText> Function(String photoPath) _recognize;

  @override
  Future<List<OcrLine>> read(String photoPath) async {
    try {
      return linesFrom(await _recognize(photoPath));
    } on Exception catch (e) {
      throw ScanException(ScanProblem.unreadable, e);
    }
  }

  /// Every line of every block, with its position in the image.
  static List<OcrLine> linesFrom(RecognizedText recognized) => [
    for (final block in recognized.blocks)
      for (final line in block.lines)
        OcrLine(
          text: line.text,
          left: line.boundingBox.left,
          top: line.boundingBox.top,
          right: line.boundingBox.right,
          bottom: line.boundingBox.bottom,
        ),
  ];
}
