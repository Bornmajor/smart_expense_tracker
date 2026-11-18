import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';

import '../support/builders.dart';
import '../support/fakes.dart';
import '../support/pump_app.dart';

/// Adding a category from the expense form with the "New" chip, so nobody has
/// to leave a half-filled form to go to Settings.
void main() {
  late FakeCategoryRepository categories;
  late FakeExpenseRepository expenses;

  setUp(() {
    categories = FakeCategoryRepository();
    expenses = FakeExpenseRepository();
  });

  Future<void> openAddForm(WidgetTester tester) async {
    await pumpRouterApp(tester, expenses: expenses, categories: categories);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tapText(tester, 'Enter manually');
  }

  Finder newChip() => find.widgetWithText(ActionChip, 'New');

  TextField field(WidgetTester tester, String label) =>
      tester.widget<TextField>(find.widgetWithText(TextField, label));

  bool isSelected(WidgetTester tester, String name) =>
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, name)).selected;

  /// Opens the sheet, types a name, and taps its Add button.
  Future<void> addFromSheet(WidgetTester tester, String name) async {
    await tester.tap(newChip());
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), name);
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Add category'));
    await tester.pumpAndSettle();
  }

  group('adding a category from the add form', () {
    testWidgets('creates it, selects it, and keeps what was typed', (
      tester,
    ) async {
      await openAddForm(tester);
      await tester.enterText(
        find.widgetWithText(TextField, 'Title (optional)'),
        'Dog walk',
      );
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '12.50');
      await tester.tap(find.text('Food'));
      await tester.pump();

      await addFromSheet(tester, '  Pets ');

      expect(find.text('New category'), findsNothing, reason: 'sheet closed');
      expect(categories.categories.map((c) => c.name), contains('Pets'));
      expect(isSelected(tester, 'Pets'), isTrue);
      expect(isSelected(tester, 'Food'), isFalse);
      expect(field(tester, 'Title (optional)').controller!.text, 'Dog walk');
      expect(field(tester, 'Amount').controller!.text, '12.50');
    });

    testWidgets('saves the expense under the new category', (tester) async {
      await openAddForm(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '8');

      await addFromSheet(tester, 'Pets');
      await tapText(tester, 'Save expense');

      final pets = categories.categories.firstWhere((c) => c.name == 'Pets');
      expect(expenses.saved.single.categoryId, pets.id);
      expect(find.text('Expense saved'), findsOneWidget);
    });

    testWidgets('a name the user already has just selects that category', (
      tester,
    ) async {
      await openAddForm(tester);

      await addFromSheet(tester, 'food');

      expect(find.text('New category'), findsNothing);
      expect(categories.categories, hasLength(2), reason: 'nothing was added');
      expect(isSelected(tester, 'Food'), isTrue);
      expect(
        find.text('You already have a category with this name'),
        findsNothing,
      );
    });

    testWidgets('asks for a name when it is blank, and stays open', (
      tester,
    ) async {
      await openAddForm(tester);

      await addFromSheet(tester, '   ');

      expect(find.text('Enter a name'), findsOneWidget);
      expect(find.text('New category'), findsOneWidget);
      expect(categories.categories, hasLength(2));
    });

    testWidgets('tells the user when saving fails, and selects nothing', (
      tester,
    ) async {
      categories.saveError = const StorageException('disk full');
      await openAddForm(tester);

      await addFromSheet(tester, 'Pets');

      expect(
        find.text('Couldn\'t save the category. Try again.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(ChoiceChip, 'Pets'), findsNothing);
    });

    testWidgets(
      'closing the sheet leaves the form and selection as they were',
      (tester) async {
        await openAddForm(tester);
        await tester.enterText(find.widgetWithText(TextField, 'Amount'), '5');
        await tester.tap(find.text('Transport'));
        await tester.pump();

        await tester.tap(newChip());
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(400, 100));
        await tester.pumpAndSettle();

        expect(find.text('New category'), findsNothing);
        expect(isSelected(tester, 'Transport'), isTrue);
        expect(field(tester, 'Amount').controller!.text, '5');
        expect(categories.categories, hasLength(2));
      },
    );

    testWidgets('can add another category after a failed attempt', (
      tester,
    ) async {
      await openAddForm(tester);

      await addFromSheet(tester, '');
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Gifts');
      await tester.tap(find.widgetWithText(FilledButton, 'Add category'));
      await tester.pumpAndSettle();

      expect(isSelected(tester, 'Gifts'), isTrue);
    });
  });

  group('adding a category from the edit form', () {
    testWidgets('moves the expense to the new category', (tester) async {
      expenses = FakeExpenseRepository(
        initial: [
          buildExpense(
            id: 'e1',
            vendor: 'Vet',
            amountMinor: 4000,
            date: DateTime.now(),
            categoryId: 'food',
          ),
        ],
      );
      await pumpRouterApp(tester, expenses: expenses, categories: categories);
      await tapText(tester, 'Vet');
      expect(find.text('Edit expense'), findsOneWidget);

      await addFromSheet(tester, 'Pets');
      await tapText(tester, 'Save changes');

      final pets = categories.categories.firstWhere((c) => c.name == 'Pets');
      expect(expenses.saved.single.id, 'e1');
      expect(expenses.saved.single.categoryId, pets.id);
    });
  });
}
