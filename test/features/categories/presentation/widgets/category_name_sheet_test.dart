import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/features/categories/presentation/widgets/category_name_sheet.dart';

void main() {
  const screen = Size(400, 800);
  bool? closedWith;

  /// Opens the sheet from a button, with the given save behavior.
  Future<void> openSheet(
    WidgetTester tester,
    Future<String?> Function(String name) onSubmit, {
    String initialName = '',
  }) async {
    closedWith = null;
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => closedWith = await showCategoryNameSheet(
                  context,
                  title: 'New category',
                  submitLabel: 'Add category',
                  initialName: initialName,
                  onSubmit: onSubmit,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, String name) async {
    await tester.enterText(find.byType(TextField), name);
    await tester.tap(find.widgetWithText(FilledButton, 'Add category'));
    await tester.pump();
  }

  group('CategoryNameSheet', () {
    testWidgets('shows the title and the starting name', (tester) async {
      await openSheet(tester, (_) async => null, initialName: 'Food');

      expect(find.text('New category'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Food',
      );
    });

    testWidgets('closes with true when the name was saved', (tester) async {
      String? received;
      await openSheet(tester, (name) async {
        received = name;
        return null;
      });

      await submit(tester, 'Pets');
      await tester.pumpAndSettle();

      expect(received, 'Pets');
      expect(find.text('New category'), findsNothing);
      expect(closedWith, isTrue);
    });

    testWidgets('stays open and shows the error it was given', (tester) async {
      await openSheet(tester, (_) async => 'Name taken');

      await submit(tester, 'Food');
      await tester.pumpAndSettle();

      expect(find.text('Name taken'), findsOneWidget);
      expect(find.text('New category'), findsOneWidget);
      expect(closedWith, isNull);
    });

    testWidgets('can submit again after an error, and clears the old one', (
      tester,
    ) async {
      var attempts = 0;
      await openSheet(
        tester,
        (_) async => ++attempts == 1 ? 'Name taken' : null,
      );

      await submit(tester, 'Food');
      await tester.pumpAndSettle();
      await submit(tester, 'Gifts');
      await tester.pumpAndSettle();

      expect(attempts, 2);
      expect(find.text('Name taken'), findsNothing);
      expect(closedWith, isTrue);
    });

    testWidgets(
      'disables the button while saving, so a double tap saves once',
      (tester) async {
        final pending = Completer<String?>();
        var calls = 0;
        await openSheet(tester, (_) {
          calls++;
          return pending.future;
        });

        await submit(tester, 'Pets');
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.tap(find.byType(FilledButton), warnIfMissed: false);
        pending.complete(null);
        await tester.pumpAndSettle();

        expect(calls, 1);
      },
    );

    testWidgets('saves from the keyboard Done key', (tester) async {
      String? received;
      await openSheet(tester, (name) async {
        received = name;
        return null;
      });

      await tester.enterText(find.byType(TextField), 'Pets');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(received, 'Pets');
    });

    testWidgets('does not accept more characters than the limit', (
      tester,
    ) async {
      await openSheet(tester, (_) async => null);

      await tester.enterText(find.byType(TextField), 'a' * 50);

      expect(
        tester
            .widget<TextField>(find.byType(TextField))
            .controller!
            .text
            .length,
        30,
      );
    });

    testWidgets('lifts the button above the keyboard', (tester) async {
      await openSheet(tester, (_) async => null);
      const keyboard = 300.0;

      tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
      await tester.pumpAndSettle();

      final button = tester.getRect(find.byType(FilledButton));
      expect(button.bottom, lessThanOrEqualTo(screen.height - keyboard));
    });
  });
}
