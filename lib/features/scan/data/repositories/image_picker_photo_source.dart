import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/receipt_source.dart';
import '../../domain/repositories/receipt_photo_source.dart';
import '../../domain/scan_exception.dart';

/// Takes a receipt photo with the system camera, or picks one from the
/// gallery, using `image_picker`.
///
/// The system camera app does the capturing, so this app never asks for the
/// camera permission itself. Gallery picks need no permission either.
class ImagePickerPhotoSource implements ReceiptPhotoSource {
  ImagePickerPhotoSource(this._picker);

  final ImagePicker _picker;

  /// Large enough for the text to stay sharp, small enough to read quickly.
  static const _maxWidth = 2000.0;
  static const _quality = 90;

  @override
  Future<String?> pick(ReceiptSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == ReceiptSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: _maxWidth,
        imageQuality: _quality,
        // Skips the extra photo-library permission on iOS.
        requestFullMetadata: false,
      );
      return file?.path;
    } on PlatformException catch (e) {
      throw ScanException(_problemFor(e), e);
    } on Exception catch (e) {
      throw ScanException(ScanProblem.cameraUnavailable, e);
    }
  }

  @override
  Future<void> discard(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on Exception {
      // Already gone, or not ours to delete. Nothing to do.
    }
  }

  ScanProblem _problemFor(PlatformException e) =>
      e.code == 'camera_access_denied' || e.code == 'photo_access_denied'
      ? ScanProblem.permissionDenied
      : ScanProblem.cameraUnavailable;
}
