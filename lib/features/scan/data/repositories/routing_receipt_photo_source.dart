import '../../domain/entities/receipt_source.dart';
import '../../domain/repositories/receipt_photo_source.dart';

/// Sends each request to the source that can handle it: the camera source for
/// the camera, and the file source for a file.
class RoutingReceiptPhotoSource implements ReceiptPhotoSource {
  const RoutingReceiptPhotoSource({required this.camera, required this.file});

  final ReceiptPhotoSource camera;
  final ReceiptPhotoSource file;

  @override
  Future<String?> pick(ReceiptSource source) => switch (source) {
    ReceiptSource.camera => camera.pick(source),
    ReceiptSource.file => file.pick(source),
  };

  /// Only choosing a file can be cut short without leaving anything behind.
  @override
  Future<bool> pickWasInterrupted() => file.pickWasInterrupted();

  /// Only the camera can lose a photo to an app restart.
  @override
  Future<String?> recoverLost() => camera.recoverLost();

  /// Either source can have made the photo, and each deletes only its own, so
  /// both are asked.
  @override
  Future<void> discard(String path) async {
    await file.discard(path);
    await camera.discard(path);
  }
}
