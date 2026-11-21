import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';
import '../support/fakes.dart';
import '../support/pump_app.dart';

/// The custom part of vendor memory: it fills in a category when the user
/// leaves the vendor field, and must never replace one the user chose.
void main() {
  Future<void> openForm(WidgetTester tester) async {
    await pumpRouterApp(
      tester,
      expenses: FakeExpenseRepository(
        initial: [buildExpense(vendor: 'Corner Cafe', categoryId: 'transport')],
      ),
    );
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tapText(tester, 'Enter manually');
  }

  Future<void> typeVendorAndLeave(WidgetTester tester, String vendor) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'Vendor (optional)'),
      vendor,
    );
    // Moving to the amount field leaves the vendor field.
    await tester.tap(find.widgetWithText(TextField, 'Amount'));
    await tester.pumpAndSettle();
  }

  bool isSelected(WidgetTester tester, String category) => tester
      .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, category))
      .selected;

  testWidgets('fills in the category used before, and says why', (
    tester,
  ) async {
    await openForm(tester);

    await typeVendorAndLeave(tester, 'corner cafe');

    expect(isSelected(tester, 'Transport'), isTrue);
    expect(find.textContaining('Chosen from your earlier expenses'), findsOne);
  });

  testWidgets('never replaces a category the user picked', (tester) async {
    await openForm(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Food'));
    await tester.pump();

    await typeVendorAndLeave(tester, 'Corner Cafe');

    expect(isSelected(tester, 'Food'), isTrue);
    expect(isSelected(tester, 'Transport'), isFalse);
    expect(
      find.textContaining('Chosen from your earlier expenses'),
      findsNothing,
    );
  });
}
