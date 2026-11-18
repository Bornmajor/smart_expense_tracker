import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/widgets/expense_tile.dart';

import '../../../../support/builders.dart';

void main() {
  Future<void> pumpTile(
    WidgetTester tester, {
    String? categoryName,
    VoidCallback? onTap,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: ExpenseTile(
          expense: buildExpense(vendor: 'Corner Cafe', amountMinor: 123456),
          categoryName: categoryName,
          onTap: onTap,
        ),
      ),
    ),
  );

  group('ExpenseTile', () {
    testWidgets('shows the vendor, category and formatted amount', (
      tester,
    ) async {
      await pumpTile(tester, categoryName: 'Food');

      expect(find.text('Corner Cafe'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('1,234.56'), findsOneWidget);
    });

    testWidgets('leaves the category out when it is not known', (tester) async {
      await pumpTile(tester);

      expect(find.text('Corner Cafe'), findsOneWidget);
      expect(find.text('Food'), findsNothing);
    });

    testWidgets('reports a tap', (tester) async {
      var taps = 0;
      await pumpTile(tester, onTap: () => taps++);

      await tester.tap(find.text('Corner Cafe'));

      expect(taps, 1);
    });
  });
}
