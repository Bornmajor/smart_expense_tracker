import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/receipt_source.dart';
import '../../domain/repositories/receipt_photo_source.dart';
import '../../domain/scan_exception.dart';

/// Takes a receipt photo with the system camera, using `image_picker`.
///
/// The system camera app does the capturing, so this app never asks for the
/// camera permission itself. Choosing an existing file is done by
/// `FileReceiptPhotoSource`.
class ImagePickerPhotoSource implements ReceiptPhotoSource {
  /// [supportsRecovery] is only for tests. Recovering a lost photo exists on
  /// Android alone, and it is the default there.
  ImagePickerPhotoSource(this._picker, {bool? supportsRecovery})
    : _supportsRecovery = supportsRecovery ?? Platform.isAndroid;

  final ImagePicker _picker;
  final bool _supportsRecovery;

  /// Large enough for the text to stay sharp, small enough to read quickly.
  static const _maxWidth = 2000.0;
  static const _quality = 90;

  @override
  Future<String?> pick(ReceiptSource source) async {
    try {
      assert(
        source == ReceiptSource.camera,
        'This source only uses the camera',
      );
      final file = await _picker.pickImage(
        source: ImageSource.camera,
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
  Future<String?> recoverLost() async {
    if (!_supportsRecovery) return null;
    try {
      final lost = await _picker.retrieveLostData();
      if (lost.isEmpty) return null;
      return (lost.file ?? lost.files?.firstOrNull)?.path;
    } on Exception {
      return null;
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
