import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/builders.dart';
import '../support/fakes.dart';
import '../support/pump_app.dart';

/// Pasting an M-Pesa message, from the Add button to a saved expense.
void main() {
  const sent =
      'SGH4A1B2C3 Confirmed. Ksh500.00 sent to JOHN DOE 0712345678 on '
      '17/7/26 at 2:15 PM. New M-PESA balance is Ksh1,234.56. Transaction '
      'cost, Ksh7.00.';
  const received =
      'SGH4A1B2C8 Confirmed.You have received Ksh2,500.00 from JANE ROE '
      '0722000000 on 18/11/26 at 10:10 AM.';

  late FakeExpenseRepository expenses;

  setUp(() => expenses = FakeExpenseRepository());

  Future<void> openMpesa(WidgetTester tester) async {
    await pumpRouterApp(tester, expenses: expenses);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tapText(tester, 'Paste an M-Pesa message');
  }

  Future<void> paste(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
  }

  String fieldText(WidgetTester tester, String label) => tester
      .widget<TextField>(find.widgetWithText(TextField, label))
      .controller!
      .text;

  testWidgets('shows what it read and fills in the form', (tester) async {
    await openMpesa(tester);

    await paste(tester, sent);
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.textContaining('incl.'), findsOneWidget);

    await tapText(tester, 'Continue');

    expect(find.text('Filled in from your M-Pesa message'), findsOneWidget);
    expect(fieldText(tester, 'Vendor (optional)'), 'John Doe');
    expect(fieldText(tester, 'Amount'), '507.00');
  });

  testWidgets('saving keeps the transaction code with the expense', (
    tester,
  ) async {
    await openMpesa(tester);
    await paste(tester, sent);
    await tapText(tester, 'Continue');

    await tester.tap(find.text('Food'));
    await tester.pump();
    await tapText(tester, 'Save expense');

    final saved = expenses.saved.single;
    expect(saved.transactionCode, 'SGH4A1B2C3');
    expect(saved.amountMinor, 50700);
    expect(saved.vendor, 'John Doe');
  });

  testWidgets('the same message again asks before adding it twice', (
    tester,
  ) async {
    expenses = FakeExpenseRepository(
      initial: [buildExpense(id: '1', transactionCode: 'SGH4A1B2C3')],
    );
    await openMpesa(tester);
    await paste(tester, sent);
    await tapText(tester, 'Continue');

    expect(find.text('Already added'), findsOneWidget);

    await tapText(tester, 'Cancel');
    expect(find.text('Filled in from your M-Pesa message'), findsNothing);

    // Once more, and this time the user adds it anyway.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tapText(tester, 'Paste an M-Pesa message');
    await paste(tester, sent);
    await tapText(tester, 'Continue');
    await tapText(tester, 'Add again');

    expect(find.text('Filled in from your M-Pesa message'), findsOneWidget);
  });

  testWidgets('money received cannot be continued, and says why', (
    tester,
  ) async {
    await openMpesa(tester);

    await paste(tester, received);

    expect(find.textContaining('money you received'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('text with no amount says so', (tester) async {
    await openMpesa(tester);

    await paste(tester, 'hello there');

    expect(find.textContaining('No amount found'), findsOneWidget);
  });
}
