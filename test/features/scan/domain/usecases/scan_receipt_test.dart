import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/result.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/categories/domain/entities/category.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/ocr_line.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/receipt_draft.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/receipt_source.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/scan_result.dart';
import 'package:smart_expense_tracker/features/scan/domain/scan_exception.dart';
import 'package:smart_expense_tracker/features/scan/domain/usecases/parse_receipt.dart';
import 'package:smart_expense_tracker/features/scan/domain/usecases/scan_receipt.dart';

import '../../../../support/fakes.dart';

/// A line of OCR text at a position: [left] across, [top] down the photo.
OcrLine ocr(String text, double left, double top) => OcrLine(
  text: text,
  left: left,
  top: top,
  right: left + 100,
  bottom: top + 20,
);

void main() {
  // A two-column receipt, in the jumbled order OCR gives: the names first,
  // then the prices.
  final receiptLines = [
    ocr('NAIVAS SUPERMARKET', 20, 10),
    ocr('Date: 16/11/2026', 20, 40),
    ocr('MILK', 20, 80),
    ocr('BREAD', 20, 110),
    ocr('TOTAL', 20, 150),
    ocr('65.00', 300, 80),
    ocr('55.00', 300, 110),
    ocr('120.00', 300, 150),
  ];

  late FakeReceiptPhotoSource photos;
  late FakeReceiptTextReader reader;
  late FakeCategoryRepository categories;
  late ScanReceipt scanReceipt;

  ScanReceipt build() => ScanReceipt(
    photos: photos,
    reader: reader,
    categories: categories,
    // A fixed "today", so the test does not depend on the real date.
    parse: ParseReceipt(now: () => DateTime(2026, 11, 18)),
  );

  Future<ScanResult> succeeded(ReceiptSource source) async {
    final result = await scanReceipt(source);
    return (result! as Success<ScanResult>).value;
  }

  ScanProblem problemOf(Result<ScanResult>? result) =>
      ((result! as Failure<ScanResult>).failure as ScanFailure).problem;

  setUp(() {
    photos = FakeReceiptPhotoSource(path: '/tmp/receipt.jpg');
    reader = FakeReceiptTextReader(receiptLines);
    categories = FakeCategoryRepository(FakeCategoryRepository.withFallback);
    // The fake categories have food, transport and other. "Supermarket" is
    // food, so a suggestion needs food to be there.
    scanReceipt = build();
  });

  group('a successful scan', () {
    test(
      'turns the photo into a draft with a vendor, date and total',
      () async {
        final result = await succeeded(ReceiptSource.camera);

        expect(
          result.draft,
          ReceiptDraft(
            vendor: 'Naivas Supermarket',
            date: DateTime(2026, 11, 16),
            totalMinor: 12000,
          ),
        );
      },
    );

    test('keeps the photo path so the form can show the receipt', () async {
      final result = await succeeded(ReceiptSource.camera);

      expect(result.photoPath, '/tmp/receipt.jpg');
    });

    test('rebuilds the rows first, so TOTAL finds its own amount', () async {
      final result = await succeeded(ReceiptSource.camera);

      expect(result.draft.totalMinor, 12000);
      expect(result.draft.totalIsGuess, isFalse);
    });

    test('suggests a category the user has', () async {
      final result = await succeeded(ReceiptSource.camera);

      expect(result.suggestedCategoryId, 'food');
    });

    test('reads the photo that was picked', () async {
      photos.path = '/tmp/other.jpg';

      await scanReceipt(ReceiptSource.camera);

      expect(reader.readPaths, ['/tmp/other.jpg']);
    });

    test(
      'does not delete the photo, because the form still needs it',
      () async {
        await scanReceipt(ReceiptSource.camera);

        expect(photos.discarded, isEmpty);
      },
    );

    test('asks for the camera or the gallery, as it was told', () async {
      await scanReceipt(ReceiptSource.camera);
      await scanReceipt(ReceiptSource.gallery);

      expect(photos.picked, [ReceiptSource.camera, ReceiptSource.gallery]);
    });
  });

  group('the category suggestion', () {
    test('is left out when the user no longer has that category', () async {
      // Only "Other" is left, so there is no category that fits a supermarket.
      categories = FakeCategoryRepository(const [
        Category(id: Category.fallbackId, name: 'Other'),
      ]);
      scanReceipt = build();

      final result = await succeeded(ReceiptSource.camera);

      expect(result.suggestedCategoryId, isNull);
      expect(result.draft.vendor, 'Naivas Supermarket');
    });

    test(
      'is left out, without failing, when categories cannot be loaded',
      () async {
        categories = _BrokenCategories();
        scanReceipt = build();

        final result = await succeeded(ReceiptSource.camera);

        expect(result.suggestedCategoryId, isNull);
        expect(result.draft.totalMinor, 12000);
      },
    );
  });

  group('when the user backs out', () {
    test('returns null and reads nothing', () async {
      photos.path = null;

      final result = await scanReceipt(ReceiptSource.camera);

      expect(result, isNull);
      expect(reader.readPaths, isEmpty);
    });

    test('has no photo to delete', () async {
      photos.path = null;

      await scanReceipt(ReceiptSource.gallery);

      expect(photos.discarded, isEmpty);
    });
  });

  group('when the camera or gallery fails', () {
    test('reports a permission problem', () async {
      photos.pickError = const ScanException(ScanProblem.permissionDenied);

      final result = await scanReceipt(ReceiptSource.camera);

      expect(problemOf(result), ScanProblem.permissionDenied);
    });

    test('reports an unavailable camera', () async {
      photos.pickError = const ScanException(ScanProblem.cameraUnavailable);

      final result = await scanReceipt(ReceiptSource.camera);

      expect(problemOf(result), ScanProblem.cameraUnavailable);
    });

    test('reads nothing, because there is no photo', () async {
      photos.pickError = const ScanException(ScanProblem.cameraUnavailable);

      await scanReceipt(ReceiptSource.camera);

      expect(reader.readPaths, isEmpty);
      expect(photos.discarded, isEmpty);
    });
  });

  group('when the text cannot be read', () {
    setUp(() => reader.error = const ScanException(ScanProblem.unreadable));

    test('reports an unreadable photo', () async {
      final result = await scanReceipt(ReceiptSource.camera);

      expect(problemOf(result), ScanProblem.unreadable);
    });

    test('deletes the photo, because nothing will show it', () async {
      await scanReceipt(ReceiptSource.camera);

      expect(photos.discarded, ['/tmp/receipt.jpg']);
    });
  });

  group('when something unexpected goes wrong', () {
    test('lets the error through, not hiding a bug', () async {
      reader.error = StateError('a bug');

      expect(scanReceipt(ReceiptSource.camera), throwsA(isA<StateError>()));
    });

    test('still deletes the photo', () async {
      reader.error = StateError('a bug');

      await expectLater(
        scanReceipt(ReceiptSource.camera),
        throwsA(isA<StateError>()),
      );

      expect(photos.discarded, ['/tmp/receipt.jpg']);
    });
  });

  group('a photo with no readable text', () {
    setUp(() => reader.lines = const []);

    test(
      'is still a success, with an empty draft for the user to fill in',
      () async {
        final result = await succeeded(ReceiptSource.camera);

        expect(result.draft.isEmpty, isTrue);
        expect(result.suggestedCategoryId, isNull);
      },
    );

    test('keeps the photo, so the user can read it themselves', () async {
      final result = await succeeded(ReceiptSource.camera);

      expect(result.photoPath, '/tmp/receipt.jpg');
      expect(photos.discarded, isEmpty);
    });
  });
}

/// Categories that cannot be loaded, like a failing database.
class _BrokenCategories extends FakeCategoryRepository {
  @override
  Future<List<Category>> getAll() async =>
      throw const StorageException('disk error');
}
