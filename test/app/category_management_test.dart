import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  late FakeCategoryRepository categories;

  setUp(() {
    categories = FakeCategoryRepository(FakeCategoryRepository.withFallback, {
      'food': 3,
      'transport': 1,
    });
  });

  Future<void> openCategories(
    WidgetTester tester, {
    Size screenSize = const Size(800, 1600),
    EdgeInsets safePadding = EdgeInsets.zero,
  }) async {
    await pumpRouterApp(
      tester,
      categories: categories,
      screenSize: screenSize,
      safePadding: safePadding,
    );
    await goToTab(tester, 'Settings');
    // Settings is a long list, and on a short screen the row may be below the
    // fold.
    await tester.scrollUntilVisible(
      find.text('Categories'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tapText(tester, 'Categories');
  }

  Finder cardFor(String name) => find.widgetWithText(Card, name);

  Finder deleteIconFor(String name) => find.descendant(
    of: cardFor(name),
    matching: find.byIcon(Icons.delete_outline),
  );

  Future<void> enterName(WidgetTester tester, String name) async {
    await tester.enterText(find.widgetWithText(TextField, 'Name'), name);
    await tester.pump();
  }

  // The sheet button shares its label with the page button behind it.
  Future<void> submitSheet(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Add category'));
    await tester.pumpAndSettle();
  }

  Future<void> addCategory(WidgetTester tester, String name) async {
    await tapText(tester, 'Add category');
    await enterName(tester, name);
    await submitSheet(tester);
  }

  group('opening Categories', () {
    testWidgets('Settings leads to the list of categories', (tester) async {
      await openCategories(tester);

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('every category but Other has a delete button', (tester) async {
      await openCategories(tester);

      expect(deleteIconFor('Food'), findsOneWidget);
      expect(deleteIconFor('Transport'), findsOneWidget);
      expect(deleteIconFor('Other'), findsNothing);
      expect(
        find.text('Takes expenses from deleted categories'),
        findsOneWidget,
      );
    });

    testWidgets('keeps the list clear of a notch on both sides', (
      tester,
    ) async {
      await openCategories(
        tester,
        screenSize: const Size(900, 400),
        safePadding: const EdgeInsets.fromLTRB(48, 0, 48, 24),
      );

      final rect = tester.getRect(cardFor('Food'));
      expect(rect.left, greaterThanOrEqualTo(48));
      expect(rect.right, lessThanOrEqualTo(900 - 48));
    });
  });

  group('adding', () {
    testWidgets('adds a category and shows it in the list', (tester) async {
      await openCategories(tester);

      await addCategory(tester, '  Pets ');

      expect(find.text('Category added'), findsOneWidget);
      expect(find.text('Pets'), findsOneWidget);
      expect(categories.categories.map((c) => c.name), contains('Pets'));
    });

    testWidgets('asks for a name when it is blank', (tester) async {
      await openCategories(tester);

      await addCategory(tester, '   ');

      expect(find.text('Enter a name'), findsOneWidget);
      expect(find.text('New category'), findsOneWidget, reason: 'sheet open');
    });

    testWidgets('does not allow a name that is already used', (tester) async {
      await openCategories(tester);

      await addCategory(tester, 'food');

      expect(
        find.text('You already have a category with this name'),
        findsOneWidget,
      );
      expect(categories.categories, hasLength(3));
    });

    testWidgets('lets the user fix the name and try again', (tester) async {
      await openCategories(tester);

      await addCategory(tester, 'Food');
      await enterName(tester, 'Gifts');
      await submitSheet(tester);

      expect(find.text('Gifts'), findsOneWidget);
      expect(find.text('Category added'), findsOneWidget);
    });

    testWidgets('tells the user when saving fails', (tester) async {
      categories.saveError = const StorageException('disk full');
      await openCategories(tester);

      await addCategory(tester, 'Pets');

      expect(
        find.text('Couldn\'t save the category. Try again.'),
        findsOneWidget,
      );
    });

    testWidgets('closing the sheet adds nothing', (tester) async {
      await openCategories(tester);

      await tapText(tester, 'Add category');
      await tester.tapAt(const Offset(400, 100));
      await tester.pumpAndSettle();

      expect(find.text('New category'), findsNothing);
      expect(find.text('Category added'), findsNothing);
      expect(categories.categories, hasLength(3));
    });
  });

  group('renaming', () {
    testWidgets('renames a category and keeps it in the list', (tester) async {
      await openCategories(tester);

      await tapText(tester, 'Food');
      expect(find.text('Rename category'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Name'))
            .controller!
            .text,
        'Food',
      );
      await enterName(tester, 'Groceries');
      await tapText(tester, 'Save name');

      expect(find.text('Category renamed'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Food'), findsNothing);
      expect(categories.categories.map((c) => c.id), contains('food'));
    });

    testWidgets('does not allow another category\'s name', (tester) async {
      await openCategories(tester);

      await tapText(tester, 'Food');
      await enterName(tester, 'Transport');
      await tapText(tester, 'Save name');

      expect(
        find.text('You already have a category with this name'),
        findsOneWidget,
      );
    });

    testWidgets('can rename Other', (tester) async {
      await openCategories(tester);

      await tapText(tester, 'Other');
      await enterName(tester, 'Misc');
      await tapText(tester, 'Save name');

      expect(find.text('Misc'), findsOneWidget);
      expect(deleteIconFor('Misc'), findsNothing, reason: 'still the fallback');
    });
  });

  group('deleting', () {
    testWidgets('says how many expenses move, then deletes', (tester) async {
      await openCategories(tester);

      await tester.tap(deleteIconFor('Food'));
      await tester.pumpAndSettle();
      expect(find.text('Delete Food?'), findsOneWidget);
      expect(
        find.text('3 expenses in this category will move to Other.'),
        findsOneWidget,
      );
      await tapText(tester, 'Delete');

      expect(
        find.text('Deleted Food. 3 expenses moved to Other.'),
        findsOneWidget,
      );
      expect(cardFor('Food'), findsNothing);
      expect(categories.deletions, [('food', 'other')]);
    });

    testWidgets('uses the singular for one expense', (tester) async {
      await openCategories(tester);

      await tester.tap(deleteIconFor('Transport'));
      await tester.pumpAndSettle();
      expect(
        find.text('1 expense in this category will move to Other.'),
        findsOneWidget,
      );
      await tapText(tester, 'Delete');

      expect(
        find.text('Deleted Transport. 1 expense moved to Other.'),
        findsOneWidget,
      );
    });

    testWidgets('a category with no expenses is deleted plainly', (
      tester,
    ) async {
      categories.expenseCounts.clear();
      await openCategories(tester);

      await tester.tap(deleteIconFor('Food'));
      await tester.pumpAndSettle();
      expect(find.text('No expenses use this category.'), findsOneWidget);
      await tapText(tester, 'Delete');

      expect(find.text('Deleted Food'), findsOneWidget);
    });

    testWidgets('names the fallback by its current name', (tester) async {
      await openCategories(tester);

      await tapText(tester, 'Other');
      await enterName(tester, 'Misc');
      await tapText(tester, 'Save name');
      await tester.tap(deleteIconFor('Food'));
      await tester.pumpAndSettle();

      expect(
        find.text('3 expenses in this category will move to Misc.'),
        findsOneWidget,
      );
    });

    testWidgets('keeps the category when the user cancels', (tester) async {
      await openCategories(tester);

      await tester.tap(deleteIconFor('Food'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Cancel');

      expect(cardFor('Food'), findsOneWidget);
      expect(categories.deletions, isEmpty);
    });

    testWidgets('tells the user when deleting fails', (tester) async {
      categories.deleteError = const StorageException('disk full');
      await openCategories(tester);

      await tester.tap(deleteIconFor('Food'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Delete');

      expect(
        find.text('Couldn\'t delete the category. Try again.'),
        findsOneWidget,
      );
      expect(cardFor('Food'), findsOneWidget);
    });
  });
}
