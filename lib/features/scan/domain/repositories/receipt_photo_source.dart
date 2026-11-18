import '../entities/receipt_source.dart';

/// Gets a receipt photo from the camera or the gallery.
abstract interface class ReceiptPhotoSource {
  /// The path of the chosen photo, or null when the user backed out.
  /// Throws `ScanException` if the camera or gallery cannot be used.
  Future<String?> pick(ReceiptSource source);

  /// A photo that was taken just before Android restarted the app, or null.
  ///
  /// Some phones kill the app within seconds of the camera opening. The photo
  /// is still saved and waits here when the app starts again. It can be taken
  /// only once. Never throws: recovery is a bonus, so any problem is null.
  Future<String?> recoverLost();

  /// Deletes a photo this source gave out. Never throws.
  Future<void> discard(String path);
}
