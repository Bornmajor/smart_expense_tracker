import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/ocr_line.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/receipt_draft.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/receipt_source.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/scan_result.dart';
import 'package:smart_expense_tracker/features/scan/domain/scan_exception.dart';
import 'package:smart_expense_tracker/features/scan/domain/usecases/parse_receipt.dart';
import 'package:smart_expense_tracker/features/scan/domain/usecases/scan_receipt.dart';
import 'package:smart_expense_tracker/features/scan/presentation/cubit/scan_cubit.dart';
import 'package:smart_expense_tracker/features/scan/presentation/cubit/scan_state.dart';

import '../../../../support/fakes.dart';

OcrLine ocr(String text, double top) =>
    OcrLine(text: text, left: 20, top: top, right: 200, bottom: top + 20);

/// A photo source that waits until the test says the user has finished with
/// the camera, so the test can act while the camera is "open".
class _SlowPhotoSource extends FakeReceiptPhotoSource {
  _SlowPhotoSource({super.path});

  final opened = Completer<void>();

  @override
  Future<String?> pick(ReceiptSource source) async {
    final photo = await super.pick(source);
    await opened.future;
    return photo;
  }
}

/// A text reader that waits until the test lets it finish.
class _SlowReader extends FakeReceiptTextReader {
  _SlowReader(super.lines);

  final finished = Completer<void>();

  @override
  Future<List<OcrLine>> read(String photoPath) async {
    final lines = await super.read(photoPath);
    await finished.future;
    return lines;
  }
}

void main() {
  late FakeReceiptPhotoSource photos;
  late FakeReceiptTextReader reader;
  late FakeCategoryRepository categories;

  // A tiny receipt: a vendor and a total.
  final lines = [ocr('Corner Cafe', 10), ocr('TOTAL 3.50', 50)];

  ScanReceipt scanReceipt() => ScanReceipt(
    photos: photos,
    reader: reader,
    categories: categories,
    parse: ParseReceipt(now: () => DateTime(2026, 11, 18)),
  );

  ScanCubit build() => ScanCubit(scanReceipt());

  /// What reading [path] should give: "Corner Cafe" is food.
  ScanResult resultFor(String path) => ScanResult(
    photoPath: path,
    draft: const ReceiptDraft(vendor: 'Corner Cafe', totalMinor: 350),
    suggestedCategoryId: 'food',
  );

  setUp(() {
    photos = FakeReceiptPhotoSource(path: '/tmp/a.jpg');
    reader = FakeReceiptTextReader(lines);
    categories = FakeCategoryRepository(FakeCategoryRepository.withFallback);
  });

  test('starts out waiting on the camera or gallery', () {
    expect(build().state, const ScanWorking(ScanStage.picking));
  });

  group('a gallery photo', () {
    blocTest<ScanCubit, ScanState>(
      'is read straight away, with no preview',
      build: build,
      act: (cubit) => cubit.start(ReceiptSource.gallery),
      expect: () => [
        const ScanWorking(ScanStage.picking),
        const ScanWorking(ScanStage.reading),
        ScanDone(resultFor('/tmp/a.jpg')),
      ],
      verify: (_) {
        expect(photos.picked, [ReceiptSource.gallery]);
        expect(photos.discarded, isEmpty, reason: 'the form still needs it');
      },
    );
  });

  group('a camera photo', () {
    blocTest<ScanCubit, ScanState>(
      'stops at a preview and reads nothing yet',
      build: build,
      act: (cubit) => cubit.start(ReceiptSource.camera),
      expect: () => const [
        ScanWorking(ScanStage.picking),
        ScanPreview('/tmp/a.jpg'),
      ],
      verify: (_) => expect(reader.readPaths, isEmpty),
    );

    blocTest<ScanCubit, ScanState>(
      'is read once the user confirms it',
      build: build,
      act: (cubit) async {
        await cubit.start(ReceiptSource.camera);
        await cubit.confirm();
      },
      expect: () => [
        const ScanWorking(ScanStage.picking),
        const ScanPreview('/tmp/a.jpg'),
        const ScanWorking(ScanStage.reading),
        ScanDone(resultFor('/tmp/a.jpg')),
      ],
      verify: (_) => expect(reader.readPaths, ['/tmp/a.jpg']),
    );

    blocTest<ScanCubit, ScanState>(
      'can be retaken: the first photo is deleted and the camera opens again',
      build: build,
      setUp: () => photos.pathQueue.addAll(['/tmp/1.jpg', '/tmp/2.jpg']),
      act: (cubit) async {
        await cubit.start(ReceiptSource.camera);
        await cubit.retake();
      },
      expect: () => const [
        ScanWorking(ScanStage.picking),
        ScanPreview('/tmp/1.jpg'),
        ScanWorking(ScanStage.picking),
        ScanPreview('/tmp/2.jpg'),
      ],
      verify: (_) {
        // The first photo was deleted by the retake. The second is deleted
        // when the test closes the cubit while it is still being previewed.
        expect(photos.discarded, ['/tmp/1.jpg', '/tmp/2.jpg']);
        expect(photos.picked, [ReceiptSource.camera, ReceiptSource.camera]);
      },
    );
  });

  group('when nothing is chosen or something fails', () {
    blocTest<ScanCubit, ScanState>(
      'backing out of the camera cancels the scan',
      build: build,
      setUp: () => photos.path = null,
      act: (cubit) => cubit.start(ReceiptSource.camera),
      expect: () => const [ScanWorking(ScanStage.picking), ScanCancelled()],
    );

    blocTest<ScanCubit, ScanState>(
      'a refused camera permission is a failure',
      build: build,
      setUp: () =>
          photos.pickError = const ScanException(ScanProblem.permissionDenied),
      act: (cubit) => cubit.start(ReceiptSource.camera),
      expect: () => const [
        ScanWorking(ScanStage.picking),
        ScanFailed(ScanProblem.permissionDenied),
      ],
    );

    blocTest<ScanCubit, ScanState>(
      'an unreadable photo is a failure, and the photo is deleted',
      build: build,
      setUp: () => reader.error = const ScanException(ScanProblem.unreadable),
      act: (cubit) => cubit.start(ReceiptSource.gallery),
      expect: () => const [
        ScanWorking(ScanStage.picking),
        ScanWorking(ScanStage.reading),
        ScanFailed(ScanProblem.unreadable),
      ],
      verify: (_) => expect(photos.discarded, ['/tmp/a.jpg']),
    );

    blocTest<ScanCubit, ScanState>(
      'an unexpected bug is reported, and the screen still ends in a failure',
      build: build,
      setUp: () => reader.error = StateError('a bug'),
      act: (cubit) => cubit.start(ReceiptSource.gallery),
      expect: () => const [
        ScanWorking(ScanStage.picking),
        ScanWorking(ScanStage.reading),
        ScanFailed(ScanProblem.unreadable),
      ],
      errors: () => [isA<StateError>()],
    );

    blocTest<ScanCubit, ScanState>(
      'can be started again after a failure',
      build: build,
      setUp: () =>
          photos.pickError = const ScanException(ScanProblem.cameraUnavailable),
      act: (cubit) async {
        await cubit.start(ReceiptSource.camera);
        photos.pickError = null;
        await cubit.start(ReceiptSource.camera);
      },
      expect: () => const [
        ScanWorking(ScanStage.picking),
        ScanFailed(ScanProblem.cameraUnavailable),
        ScanWorking(ScanStage.picking),
        ScanPreview('/tmp/a.jpg'),
      ],
    );
  });

  group('a photo recovered after the app was restarted', () {
    blocTest<ScanCubit, ScanState>(
      'goes to the preview, marked as recovered',
      build: build,
      act: (cubit) => cubit.resume('/cache/lost.jpg'),
      expect: () => const [ScanPreview('/cache/lost.jpg', recovered: true)],
      verify: (_) => expect(reader.readPaths, isEmpty),
    );

    blocTest<ScanCubit, ScanState>(
      'is read once confirmed, like any camera photo',
      build: build,
      act: (cubit) async {
        cubit.resume('/cache/lost.jpg');
        await cubit.confirm();
      },
      expect: () => [
        const ScanPreview('/cache/lost.jpg', recovered: true),
        const ScanWorking(ScanStage.reading),
        ScanDone(resultFor('/cache/lost.jpg')),
      ],
    );

    blocTest<ScanCubit, ScanState>(
      'can be retaken: the recovered photo is deleted and the camera opens',
      build: build,
      setUp: () => photos.pathQueue.add('/tmp/new.jpg'),
      act: (cubit) async {
        cubit.resume('/cache/lost.jpg');
        await cubit.retake();
      },
      expect: () => const [
        ScanPreview('/cache/lost.jpg', recovered: true),
        ScanWorking(ScanStage.picking),
        ScanPreview('/tmp/new.jpg'),
      ],
      verify: (_) {
        // The recovered photo was deleted by the retake. The new one is
        // deleted when the test closes the cubit while it is being previewed.
        expect(photos.discarded, ['/cache/lost.jpg', '/tmp/new.jpg']);
        expect(photos.picked, [ReceiptSource.camera]);
      },
    );
  });

  group('actions that do not apply', () {
    blocTest<ScanCubit, ScanState>(
      'confirm does nothing when there is no preview',
      build: build,
      act: (cubit) => cubit.confirm(),
      expect: () => const <ScanState>[],
      verify: (_) => expect(reader.readPaths, isEmpty),
    );

    blocTest<ScanCubit, ScanState>(
      'retake does nothing when there is no preview',
      build: build,
      act: (cubit) => cubit.retake(),
      expect: () => const <ScanState>[],
      verify: (_) {
        expect(photos.picked, isEmpty);
        expect(photos.discarded, isEmpty);
      },
    );

    test('a second start while the camera is open is ignored', () async {
      final slow = _SlowPhotoSource(path: '/tmp/a.jpg');
      photos = slow;
      final cubit = build();

      final first = cubit.start(ReceiptSource.camera);
      await cubit.start(ReceiptSource.camera);
      slow.opened.complete();
      await first;

      expect(photos.picked, [ReceiptSource.camera], reason: 'opened once');
      await cubit.close();
    });
  });

  group('leaving the screen', () {
    test('while previewing deletes the photo', () async {
      final cubit = build();
      await cubit.start(ReceiptSource.camera);

      await cubit.close();

      expect(photos.discarded, ['/tmp/a.jpg']);
    });

    test(
      'while the camera is open deletes the photo that arrives later',
      () async {
        final slow = _SlowPhotoSource(path: '/tmp/late.jpg');
        photos = slow;
        final cubit = build();

        final starting = cubit.start(ReceiptSource.camera);
        await cubit.close();
        slow.opened.complete();
        await starting;

        expect(photos.discarded, ['/tmp/late.jpg']);
      },
    );

    test('while reading deletes the photo once it has been read', () async {
      final slowReader = _SlowReader(lines);
      reader = slowReader;
      final cubit = build();

      final starting = cubit.start(ReceiptSource.gallery);
      await pumpEventQueue();
      expect(cubit.state, const ScanWorking(ScanStage.reading));
      await cubit.close();
      slowReader.finished.complete();
      await starting;

      expect(photos.discarded, ['/tmp/a.jpg']);
    });

    test('after finishing does not delete the photo the form shows', () async {
      final cubit = build();
      await cubit.start(ReceiptSource.gallery);

      await cubit.close();

      expect(cubit.state, isA<ScanDone>());
      expect(photos.discarded, isEmpty);
    });
  });
}
