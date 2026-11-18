import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/features/scan/data/repositories/image_picker_photo_source.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/receipt_source.dart';
import 'package:smart_expense_tracker/features/scan/domain/scan_exception.dart';

/// A stand-in for the real `ImagePicker`. The real one opens the camera, which
/// a test cannot do, so this one records how it was asked and answers as told.
class FakeImagePicker implements ImagePicker {
  /// The photo "taken". Null means the user backed out.
  String? path = '/tmp/photo.jpg';

  /// When set, `pickImage` throws it.
  Object? error;

  // What the wrapper asked for.
  ImageSource? source;
  double? maxWidth;
  int? imageQuality;
  bool? requestFullMetadata;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    this.source = source;
    this.maxWidth = maxWidth;
    this.imageQuality = imageQuality;
    this.requestFullMetadata = requestFullMetadata;

    final problem = error;
    if (problem != null) throw problem;
    final chosen = path;
    return chosen == null ? null : XFile(chosen);
  }

  /// What Android left behind when it killed the app during capture.
  LostDataResponse lost = LostDataResponse.empty();

  /// When set, `retrieveLostData` throws it.
  Object? lostError;

  @override
  Future<LostDataResponse> retrieveLostData() async {
    final problem = lostError;
    if (problem != null) throw problem;
    return lost;
  }

  // The wrapper only calls pickImage and retrieveLostData. Anything else
  // would be a mistake.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeImagePicker picker;
  late ImagePickerPhotoSource source;

  /// The problem a failed pick was turned into.
  Future<ScanException> failureOf(ReceiptSource from) async {
    try {
      await source.pick(from);
    } on ScanException catch (e) {
      return e;
    }
    fail('expected a ScanException');
  }

  setUp(() {
    picker = FakeImagePicker();
    source = ImagePickerPhotoSource(picker);
  });

  group('choosing a photo', () {
    test('opens the camera for the camera source', () async {
      await source.pick(ReceiptSource.camera);

      expect(picker.source, ImageSource.camera);
    });

    test('opens the gallery for the gallery source', () async {
      await source.pick(ReceiptSource.gallery);

      expect(picker.source, ImageSource.gallery);
    });

    test('returns the path of the photo', () async {
      picker.path = '/cache/IMG_0042.jpg';

      expect(await source.pick(ReceiptSource.camera), '/cache/IMG_0042.jpg');
    });

    test('returns null when the user backs out', () async {
      picker.path = null;

      expect(await source.pick(ReceiptSource.camera), isNull);
    });

    test('asks for a photo that is sharp enough but not huge', () async {
      await source.pick(ReceiptSource.camera);

      expect(picker.maxWidth, 2000);
      expect(picker.imageQuality, 90);
    });

    test('skips the extra photo-library permission on iOS', () async {
      await source.pick(ReceiptSource.gallery);

      expect(picker.requestFullMetadata, isFalse);
    });
  });

  group('when picking fails', () {
    test('a camera permission refusal is a permission problem', () async {
      picker.error = PlatformException(code: 'camera_access_denied');

      final problem = await failureOf(ReceiptSource.camera);

      expect(problem.problem, ScanProblem.permissionDenied);
    });

    test('a photo permission refusal is a permission problem', () async {
      picker.error = PlatformException(code: 'photo_access_denied');

      final problem = await failureOf(ReceiptSource.gallery);

      expect(problem.problem, ScanProblem.permissionDenied);
    });

    test('any other platform error means the camera is unavailable', () async {
      picker.error = PlatformException(code: 'already_active');

      final problem = await failureOf(ReceiptSource.camera);

      expect(problem.problem, ScanProblem.cameraUnavailable);
    });

    test(
      'an unexpected exception also means the camera is unavailable',
      () async {
        picker.error = Exception('no camera on this device');

        final problem = await failureOf(ReceiptSource.camera);

        expect(problem.problem, ScanProblem.cameraUnavailable);
      },
    );

    test('keeps the original error for debugging', () async {
      final original = PlatformException(code: 'camera_access_denied');
      picker.error = original;

      final problem = await failureOf(ReceiptSource.camera);

      expect(problem.cause, same(original));
    });
  });

  group('recovering a photo lost when Android restarted the app', () {
    late ImagePickerPhotoSource android;

    // Recovery exists on Android only, so these tests turn it on.
    setUp(
      () => android = ImagePickerPhotoSource(picker, supportsRecovery: true),
    );

    test('returns the path of the photo that was waiting', () async {
      picker.lost = LostDataResponse(
        file: XFile('/cache/lost.jpg'),
        type: RetrieveType.image,
      );

      expect(await android.recoverLost(), '/cache/lost.jpg');
    });

    test('returns the first photo when the answer is a list', () async {
      picker.lost = LostDataResponse(
        files: [XFile('/cache/a.jpg'), XFile('/cache/b.jpg')],
        type: RetrieveType.image,
      );

      expect(await android.recoverLost(), '/cache/a.jpg');
    });

    test('returns null when nothing was lost', () async {
      expect(await android.recoverLost(), isNull);
    });

    test('returns null when the lost result was a failure', () async {
      picker.lost = LostDataResponse(
        exception: PlatformException(code: 'camera_failed'),
        type: RetrieveType.image,
      );

      expect(await android.recoverLost(), isNull);
    });

    test('never throws: any problem is just null', () async {
      picker.lostError = Exception('plugin trouble');

      expect(await android.recoverLost(), isNull);
    });

    test('does not even ask on platforms that cannot recover', () async {
      picker.lost = LostDataResponse(file: XFile('/cache/lost.jpg'));
      picker.lostError = StateError('would be called');

      // The default source on this PC (not Android) has recovery off.
      expect(await source.recoverLost(), isNull);
    });
  });

  group('discarding a photo', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('receipt_test_'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('deletes the file', () async {
      final file = File('${dir.path}/receipt.jpg')..writeAsStringSync('photo');

      await source.discard(file.path);

      expect(file.existsSync(), isFalse);
    });

    test('does nothing when the file is already gone', () async {
      final path = '${dir.path}/missing.jpg';

      await source.discard(path);

      expect(File(path).existsSync(), isFalse);
    });

    test('leaves other files alone', () async {
      final keep = File('${dir.path}/keep.jpg')..writeAsStringSync('keep');
      final drop = File('${dir.path}/drop.jpg')..writeAsStringSync('drop');

      await source.discard(drop.path);

      expect(keep.existsSync(), isTrue);
    });

    test('never throws, even for a path that cannot be a file', () async {
      await source.discard('');
      await source.discard(dir.path);

      expect(dir.existsSync(), isTrue, reason: 'a folder is not deleted');
    });
  });
}
