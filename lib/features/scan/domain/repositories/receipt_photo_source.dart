import '../entities/receipt_source.dart';

/// Gets a receipt photo from the camera or the gallery.
abstract interface class ReceiptPhotoSource {
  /// The path of the chosen photo, or null when the user backed out.
  /// Throws `ScanException` if the camera or gallery cannot be used.
  Future<String?> pick(ReceiptSource source);

  /// Deletes a photo this source gave out. Never throws.
  Future<void> discard(String path);
}
