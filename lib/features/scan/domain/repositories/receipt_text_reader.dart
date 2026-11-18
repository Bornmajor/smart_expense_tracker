import '../entities/ocr_line.dart';

/// Reads the text in a photo, on the device. Nothing is uploaded.
abstract interface class ReceiptTextReader {
  /// The lines of text in the photo, each with its position.
  /// Throws `ScanException` if the photo cannot be read.
  Future<List<OcrLine>> read(String photoPath);
}
