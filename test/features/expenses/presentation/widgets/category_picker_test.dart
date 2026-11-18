import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/widgets/category_picker.dart';

import '../../../../support/fakes.dart';

void main() {
  Future<void> pumpPicker(
    WidgetTester tester, {
    String? selectedId,
    ValueChanged<String>? onSelected,
    VoidCallback? onAdd,
    String? errorText,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider(
          create: (_) => CategoriesCubit(FakeCategoryRepository()),
          child: Scaffold(
            body: CategoryPicker(
              selectedId: selectedId,
              onSelected: onSelected ?? (_) {},
              onAdd: onAdd,
              errorText: errorText,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CategoryPicker', () {
    testWidgets('shows a chip for each category and marks the selected one', (
      tester,
    ) async {
      await pumpPicker(tester, selectedId: 'food');

      expect(find.widgetWithText(ChoiceChip, 'Food'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Transport'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Food'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Transport'))
            .selected,
        isFalse,
      );
    });

    testWidgets('reports the chosen category', (tester) async {
      String? chosen;
      await pumpPicker(tester, onSelected: (id) => chosen = id);

      await tester.tap(find.text('Transport'));

      expect(chosen, 'transport');
    });

    testWidgets('shows a New chip after the categories when it can add', (
      tester,
    ) async {
      await pumpPicker(tester, onAdd: () {});

      final newChip = find.widgetWithText(ActionChip, 'New');
      expect(newChip, findsOneWidget);
      expect(
        tester.getTopLeft(newChip).dx,
        greaterThan(tester.getTopLeft(find.text('Transport')).dx),
        reason: 'it comes last, after the categories',
      );
    });

    testWidgets('has no New chip unless adding is possible', (tester) async {
      await pumpPicker(tester);

      expect(find.widgetWithText(ActionChip, 'New'), findsNothing);
    });

    testWidgets('tapping New asks to add a category', (tester) async {
      var taps = 0;
      await pumpPicker(tester, onAdd: () => taps++);

      await tester.tap(find.widgetWithText(ActionChip, 'New'));

      expect(taps, 1);
    });

    testWidgets('shows the error text', (tester) async {
      await pumpPicker(tester, errorText: 'Choose a category');

      expect(find.text('Choose a category'), findsOneWidget);
    });
  });
}
