import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/receipt_draft.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/scan_result.dart';
import 'package:smart_expense_tracker/features/scan/presentation/scan_messages.dart';

void main() {
  ScanResult scan(ReceiptDraft draft, {String? category}) => ScanResult(
    photoPath: '/tmp/receipt.jpg',
    draft: draft,
    suggestedCategoryId: category,
  );

  final full = ReceiptDraft(
    vendor: 'Cafe',
    date: DateTime(2026, 11, 16),
    totalMinor: 350,
  );

  group('scanFailureMessage', () {
    test('has a different, non-empty message for every problem', () {
      final messages = [
        for (final problem in ScanProblem.values) scanFailureMessage(problem),
      ];

      expect(messages.every((m) => m.isNotEmpty), isTrue);
      expect(messages.toSet(), hasLength(ScanProblem.values.length));
    });

    test('tells the user where to allow access when permission is refused', () {
      expect(
        scanFailureMessage(ScanProblem.permissionDenied),
        contains('settings'),
      );
    });

    test('every message offers entering the expense by hand', () {
      for (final problem in ScanProblem.values) {
        expect(scanFailureMessage(problem), contains('by hand'));
      }
    });
  });

  group('scanReviewNotes', () {
    test('a complete reading just asks the user to check', () {
      expect(scanReviewNotes(scan(full)), [
        'Check the details below before you save.',
      ]);
    });

    test('an empty reading says nothing was read, and nothing else', () {
      expect(scanReviewNotes(scan(const ReceiptDraft())), [
        'We couldn\'t read anything from this receipt. '
            'Fill in the details yourself.',
      ]);
    });

    test('a missing total asks for the amount', () {
      final notes = scanReviewNotes(
        scan(ReceiptDraft(vendor: 'Cafe', date: DateTime(2026, 11, 16))),
      );

      expect(
        notes,
        contains('We couldn\'t find the total, so enter the amount.'),
      );
    });

    test('a guessed total asks to check the amount', () {
      final notes = scanReviewNotes(
        scan(
          ReceiptDraft(
            vendor: 'Cafe',
            date: DateTime(2026, 11, 16),
            totalMinor: 350,
            totalIsGuess: true,
          ),
        ),
      );

      expect(
        notes,
        contains('We couldn\'t find a total line, so check the amount.'),
      );
      expect(
        notes,
        isNot(contains('We couldn\'t find the total, so enter the amount.')),
      );
    });

    test('a missing date says today\'s date is used', () {
      final notes = scanReviewNotes(
        scan(const ReceiptDraft(vendor: 'Cafe', totalMinor: 350)),
      );

      expect(
        notes,
        contains('We couldn\'t read the date, so today\'s date is filled in.'),
      );
    });

    test('a suggested category is mentioned as a suggestion', () {
      final notes = scanReviewNotes(scan(full, category: 'food'));

      expect(
        notes,
        contains('We suggested a category. Change it if it\'s wrong.'),
      );
    });

    test('a category from earlier expenses is said to come from them', () {
      final notes = scanReviewNotes(
        ScanResult(
          photoPath: '/tmp/receipt.jpg',
          draft: full,
          suggestedCategoryId: 'food',
          categoryFromHistory: true,
        ),
      );

      expect(
        notes,
        contains(
          'We chose the category you used for this vendor before. '
          'Change it if it\'s wrong.',
        ),
      );
      expect(
        notes,
        isNot(contains('We suggested a category. Change it if it\'s wrong.')),
      );
    });

    test('no suggestion, no note about one', () {
      final notes = scanReviewNotes(scan(full));

      expect(notes.any((n) => n.contains('suggested')), isFalse);
    });

    test('the check note always comes first when something was read', () {
      final notes = scanReviewNotes(
        scan(const ReceiptDraft(totalMinor: 100), category: 'food'),
      );

      expect(notes.first, 'Check the details below before you save.');
      expect(notes.length, greaterThan(1));
    });
  });
}
