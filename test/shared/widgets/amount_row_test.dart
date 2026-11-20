import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/shared/widgets/amount_row.dart';

void main() {
  // The one thing that can break: a long amount (a big sum with a currency
  // symbol, at large text on a small phone) pushing the row past the screen.
  testWidgets('a long amount at large text shrinks instead of overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AmountRow(
            leading: Text('Lunch with the whole team'),
            amount: 'KSh 1,234,567,890.00',
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Lunch'), findsOneWidget);
  });
}
