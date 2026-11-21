import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/result.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:smart_expense_tracker/features/expenses/domain/usecases/vendor_category_memory.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/ocr_line.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/receipt_source.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/scan_result.dart';
import 'package:smart_expense_tracker/features/scan/domain/usecases/parse_receipt.dart';
import 'package:smart_expense_tracker/features/scan/domain/usecases/scan_receipt.dart';

import '../../../../support/builders.dart';
import '../../../../support/fakes.dart';

/// Scanning uses what the user did with a vendor before, ahead of a guess from
/// the words on the receipt.
void main() {
  OcrLine ocr(String text, double top) =>
      OcrLine(text: text, left: 20, top: top, right: 220, bottom: top + 20);

  late FakeReceiptPhotoSource photos;
  late FakeReceiptTextReader reader;

  Future<ScanResult> scanWith({
    required List<OcrLine> lines,
    List<Expense> history = const [],
    FakeCategoryRepository? categories,
  }) async {
    reader = FakeReceiptTextReader(lines);
    final scan = ScanReceipt(
      photos: photos,
      reader: reader,
      categories:
          categories ??
          FakeCategoryRepository(FakeCategoryRepository.withFallback),
      memory: VendorCategoryMemory(FakeExpenseRepository(initial: history)),
      parse: ParseReceipt(now: () => DateTime(2026, 11, 18)),
    );

    final picked = await scan.pick(ReceiptSource.file);
    final result = await scan.read((picked! as Success<String>).value);
    return (result as Success<ScanResult>).value;
  }

  setUp(() => photos = FakeReceiptPhotoSource(path: '/tmp/receipt.jpg'));

  // "Supermarket" points to Food in the word list.
  final naivas = [ocr('NAIVAS SUPERMARKET', 10), ocr('TOTAL 120.00', 60)];

  test('uses the category the user gave this vendor before', () async {
    final result = await scanWith(
      lines: naivas,
      history: [
        buildExpense(vendor: 'Naivas Supermarket', categoryId: 'transport'),
      ],
    );

    expect(result.suggestedCategoryId, 'transport');
    expect(result.categoryFromHistory, isTrue);
  });

  test('beats the guess from the words on the receipt', () async {
    // Without history the same receipt is guessed as Food.
    final guessed = await scanWith(lines: naivas);
    expect(guessed.suggestedCategoryId, 'food');

    final remembered = await scanWith(
      lines: naivas,
      history: [
        buildExpense(vendor: 'Naivas Supermarket', categoryId: 'transport'),
      ],
    );
    expect(remembered.suggestedCategoryId, isNot(guessed.suggestedCategoryId));
  });

  test('says the suggestion is a guess when there is no history', () async {
    final result = await scanWith(lines: naivas);

    expect(result.suggestedCategoryId, 'food');
    expect(result.categoryFromHistory, isFalse);
  });

  test('matches the vendor however the receipt capitalises it', () async {
    final result = await scanWith(
      lines: [ocr('Naivas SUPERMARKET', 10), ocr('TOTAL 120.00', 60)],
      history: [
        buildExpense(vendor: 'naivas supermarket', categoryId: 'transport'),
      ],
    );

    expect(result.suggestedCategoryId, 'transport');
  });

  test('another vendor\'s history does not apply', () async {
    final result = await scanWith(
      lines: naivas,
      history: [buildExpense(vendor: 'Quickmart', categoryId: 'transport')],
    );

    expect(result.suggestedCategoryId, 'food');
    expect(result.categoryFromHistory, isFalse);
  });

  test('ignores a remembered category the user has since deleted', () async {
    final result = await scanWith(
      lines: naivas,
      history: [
        buildExpense(vendor: 'Naivas Supermarket', categoryId: 'deleted'),
      ],
    );

    // Falls back to the words on the receipt.
    expect(result.suggestedCategoryId, 'food');
    expect(result.categoryFromHistory, isFalse);
  });

  test(
    'suggests nothing when there is no history and no clear words',
    () async {
      final result = await scanWith(
        lines: [ocr('ZZQ TRADERS', 10), ocr('TOTAL 120.00', 60)],
      );

      expect(result.suggestedCategoryId, isNull);
      expect(result.categoryFromHistory, isFalse);
    },
  );

  test(
    'a receipt with no readable vendor uses the words, not history',
    () async {
      final result = await scanWith(
        lines: [ocr('TOTAL 120.00', 60)],
        history: [buildExpense(vendor: 'Unknown', categoryId: 'transport')],
      );

      expect(result.categoryFromHistory, isFalse);
    },
  );
}
