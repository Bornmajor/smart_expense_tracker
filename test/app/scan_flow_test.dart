import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/features/categories/domain/entities/category.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/ocr_line.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/receipt_source.dart';
import 'package:smart_expense_tracker/features/scan/domain/scan_exception.dart';
import 'package:smart_expense_tracker/features/scan/presentation/widgets/scan_review_panel.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

OcrLine ocr(String text, double left, double top) => OcrLine(
  text: text,
  left: left,
  top: top,
  right: left + 100,
  bottom: top + 20,
);

/// Scanning a receipt photo from the gallery, from the Add expense button to a
/// saved expense. The camera and the text reading are fakes.
void main() {
  late FakeReceiptPhotoSource photos;
  late FakeReceiptTextReader reader;
  late FakeExpenseRepository expenses;

  // A two-column receipt, as OCR hands it over: names first, then prices.
  final receipt = [
    ocr('NAIVAS SUPERMARKET', 20, 10),
    ocr('Date: 16/11/2020', 20, 40),
    ocr('MILK', 20, 80),
    ocr('TOTAL', 20, 120),
    ocr('65.00', 300, 80),
    ocr('120.00', 300, 120),
  ];

  setUp(() {
    photos = FakeReceiptPhotoSource(path: '/tmp/receipt.jpg');
    reader = FakeReceiptTextReader(receipt);
    expenses = FakeExpenseRepository();
  });

  Future<void> openApp(WidgetTester tester, {FakeCategoryRepository? cats}) =>
      pumpRouterApp(
        tester,
        photos: photos,
        reader: reader,
        expenses: expenses,
        categories:
            cats ?? FakeCategoryRepository(FakeCategoryRepository.withFallback),
      );

  Future<void> chooseReceiptPhoto(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tapText(tester, 'Choose a receipt file');
  }

  /// The receipt photo in the review panel (the part that can be tapped).
  Finder receiptPhoto() => find.descendant(
    of: find.byType(ScanReviewPanel),
    matching: find.byType(Image),
  );

  TextField field(WidgetTester tester, String label) =>
      tester.widget<TextField>(find.widgetWithText(TextField, label));

  group('a scanned receipt fills in the form', () {
    testWidgets('with the vendor, the total and the date', (tester) async {
      await openApp(tester);

      await chooseReceiptPhoto(tester);

      expect(find.text('Add expense'), findsOneWidget);
      expect(
        field(tester, 'Vendor (optional)').controller!.text,
        'Naivas Supermarket',
      );
      expect(field(tester, 'Amount').controller!.text, '120.00');
      expect(find.text('Nov 16, 2020'), findsOneWidget);
    });

    testWidgets('and selects the category it suggests', (tester) async {
      await openApp(tester);

      await chooseReceiptPhoto(tester);

      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Food'))
            .selected,
        isTrue,
      );
    });

    testWidgets('and shows the receipt with what to check', (tester) async {
      await openApp(tester);

      await chooseReceiptPhoto(tester);

      expect(find.text('Read from your receipt'), findsOneWidget);
      expect(
        find.text('Check the details below before you save.'),
        findsOneWidget,
      );
      expect(
        find.text('We suggested a category. Change it if it\'s wrong.'),
        findsOneWidget,
      );
      expect(receiptPhoto(), findsOneWidget);
    });

    testWidgets('and saves the expense with the scanned values', (
      tester,
    ) async {
      await openApp(tester);

      await chooseReceiptPhoto(tester);
      await tapText(tester, 'Save expense');

      final saved = expenses.saved.single;
      expect(saved.vendor, 'Naivas Supermarket');
      expect(saved.amountMinor, 12000);
      expect(saved.categoryId, 'food');
      expect(saved.date, DateTime(2020, 11, 16));
      expect(find.text('Expense saved'), findsOneWidget);
    });

    testWidgets('and lets the user correct a value before saving', (
      tester,
    ) async {
      await openApp(tester);

      await chooseReceiptPhoto(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '99.50');
      await tapText(tester, 'Save expense');

      expect(expenses.saved.single.amountMinor, 9950);
    });
  });

  group('what the form says about a weak reading', () {
    testWidgets('a total that is only a guess is flagged', (tester) async {
      reader.lines = [ocr('CORNER CAFE', 20, 10), ocr('COFFEE 3.50', 20, 50)];
      await openApp(tester);

      await chooseReceiptPhoto(tester);

      expect(
        find.text('We couldn\'t find a total line, so check the amount.'),
        findsOneWidget,
      );
      expect(field(tester, 'Amount').controller!.text, '3.50');
    });

    testWidgets('a missing date falls back to today and says so', (
      tester,
    ) async {
      reader.lines = [ocr('CORNER CAFE', 20, 10), ocr('TOTAL 3.50', 20, 50)];
      await openApp(tester);

      await chooseReceiptPhoto(tester);

      expect(
        find.text('We couldn\'t read the date, so today\'s date is filled in.'),
        findsOneWidget,
      );
    });

    testWidgets('a photo with no text opens an empty form with a note', (
      tester,
    ) async {
      reader.lines = const [];
      await openApp(tester);

      await chooseReceiptPhoto(tester);

      expect(find.text('Add expense'), findsOneWidget);
      expect(
        find.text(
          'We couldn\'t read anything from this receipt. '
          'Fill in the details yourself.',
        ),
        findsOneWidget,
      );
      expect(field(tester, 'Amount').controller!.text, isEmpty);
    });

    testWidgets('no matching category leaves the choice to the user', (
      tester,
    ) async {
      await openApp(
        tester,
        cats: FakeCategoryRepository(const [
          // Only a category that does not fit this receipt.
          Category(id: 'transport', name: 'Transport'),
        ]),
      );
      reader.lines = [ocr('ZYX LTD', 20, 10), ocr('TOTAL 5.00', 20, 50)];

      await chooseReceiptPhoto(tester);

      expect(
        tester
            .widgetList<ChoiceChip>(find.byType(ChoiceChip))
            .any((c) => c.selected),
        isFalse,
      );
    });
  });

  group('the receipt photo is deleted when the form closes', () {
    testWidgets('after saving', (tester) async {
      await openApp(tester);

      await chooseReceiptPhoto(tester);
      expect(photos.discarded, isEmpty, reason: 'still on screen');
      await tapText(tester, 'Save expense');

      expect(photos.discarded, ['/tmp/receipt.jpg']);
    });

    testWidgets('after leaving without saving', (tester) async {
      await openApp(tester);

      await chooseReceiptPhoto(tester);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(photos.discarded, ['/tmp/receipt.jpg']);
      expect(expenses.saved, isEmpty);
    });
  });

  group('the receipt photo can be enlarged', () {
    testWidgets('tapping it opens it full screen, and it can be closed', (
      tester,
    ) async {
      await openApp(tester);
      await chooseReceiptPhoto(tester);

      await tester.tap(receiptPhoto());
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsNothing);
    });
  });

  group('when the user backs out or something fails', () {
    testWidgets('backing out of the picker returns to the list', (
      tester,
    ) async {
      photos.path = null;
      await openApp(tester);

      await chooseReceiptPhoto(tester);

      expect(find.text('Add your first expense'), findsOneWidget);
      expect(find.text('Scan receipt'), findsNothing);
      expect(find.text('Save expense'), findsNothing, reason: 'no form opened');
    });

    testWidgets('a refused permission is explained, with a way forward', (
      tester,
    ) async {
      photos.pickError = const ScanException(ScanProblem.permissionDenied);
      await openApp(tester);

      await chooseReceiptPhoto(tester);

      expect(find.textContaining('can\'t open your photos'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Enter manually'), findsOneWidget);
    });

    testWidgets('Try again opens the picker once more', (tester) async {
      photos.pickError = const ScanException(ScanProblem.cameraUnavailable);
      await openApp(tester);

      await chooseReceiptPhoto(tester);
      photos.pickError = null;
      await tapText(tester, 'Try again');

      expect(photos.picked, [ReceiptSource.file, ReceiptSource.file]);
      expect(find.text('Add expense'), findsOneWidget);
    });

    testWidgets('an unreadable photo is explained, and is deleted', (
      tester,
    ) async {
      reader.error = const ScanException(ScanProblem.unreadable);
      await openApp(tester);

      await chooseReceiptPhoto(tester);

      expect(
        find.textContaining('couldn\'t read this receipt'),
        findsOneWidget,
      );
      expect(photos.discarded, ['/tmp/receipt.jpg']);
    });

    testWidgets('Enter manually opens an empty form', (tester) async {
      reader.error = const ScanException(ScanProblem.unreadable);
      await openApp(tester);

      await chooseReceiptPhoto(tester);
      await tapText(tester, 'Enter manually');

      expect(find.text('Add expense'), findsOneWidget);
      expect(field(tester, 'Amount').controller!.text, isEmpty);
      expect(find.text('Read from your receipt'), findsNothing);
    });

    testWidgets('the form after Enter manually goes back to the list', (
      tester,
    ) async {
      reader.error = const ScanException(ScanProblem.unreadable);
      await openApp(tester);

      await chooseReceiptPhoto(tester);
      await tapText(tester, 'Enter manually');
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Add your first expense'), findsOneWidget);
    });
  });

  group('adding by hand is unchanged', () {
    testWidgets('has no receipt panel and does not touch the scan', (
      tester,
    ) async {
      await openApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tapText(tester, 'Enter manually');

      expect(find.text('Add expense'), findsOneWidget);
      expect(find.text('Read from your receipt'), findsNothing);
      expect(photos.picked, isEmpty);
      expect(reader.readPaths, isEmpty);
    });
  });

  group('a photo kept from before Android closed the app', () {
    testWidgets('opens on its preview when the app starts', (tester) async {
      photos.recoverPath = '/cache/lost.jpg';

      await openApp(tester);

      expect(
        find.textContaining('restarted the app while the camera was open'),
        findsOneWidget,
      );
      expect(find.text('Use this photo'), findsOneWidget);
      expect(photos.picked, isEmpty);
    });

    testWidgets('says so when a file pick was cut short', (tester) async {
      photos.interrupted = true;

      await openApp(tester);

      expect(
        find.textContaining('closed the app while you were choosing'),
        findsOneWidget,
      );
      expect(find.text('Use this photo'), findsNothing);
    });

    testWidgets('leaves the list alone when there is none', (tester) async {
      await openApp(tester);

      expect(find.text('Use this photo'), findsNothing);
    });
  });
}
