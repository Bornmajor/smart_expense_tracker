import 'package:flutter_test/flutter_test.dart';

import 'package:smart_expense_tracker/app.dart';

void main() {
  testWidgets('App builds and shows the theme preview', (tester) async {
    await tester.pumpWidget(const SpendWiseApp());

    expect(find.text('Add expense'), findsOneWidget);
    expect(find.text('Save expense'), findsOneWidget);
  });
}
