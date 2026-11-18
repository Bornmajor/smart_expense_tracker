import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/widgets/expense_tile.dart';

import '../../../../support/builders.dart';

void main() {
  Future<void> pumpTile(
    WidgetTester tester, {
    String? categoryName,
    String title = '',
    String vendor = 'Corner Cafe',
    VoidCallback? onTap,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: ExpenseTile(
          expense: buildExpense(
            title: title,
            vendor: vendor,
            amountMinor: 123456,
          ),
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

    testWidgets('leads with the title, with vendor and category below', (
      tester,
    ) async {
      await pumpTile(tester, title: 'Team lunch', categoryName: 'Food');

      expect(find.text('Team lunch'), findsOneWidget);
      expect(find.text('Corner Cafe · Food'), findsOneWidget);
      expect(find.text('Corner Cafe'), findsNothing);
    });

    testWidgets('leaves an unknown vendor out of the details', (tester) async {
      await pumpTile(
        tester,
        title: 'Team lunch',
        vendor: 'Unknown',
        categoryName: 'Food',
      );

      expect(find.text('Team lunch'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.textContaining('Unknown'), findsNothing);
    });

    testWidgets('shows only the vendor when there is a title but no category', (
      tester,
    ) async {
      await pumpTile(tester, title: 'Team lunch');

      expect(find.text('Corner Cafe'), findsOneWidget);
    });

    testWidgets('reports a tap', (tester) async {
      var taps = 0;
      await pumpTile(tester, onTap: () => taps++);

      await tester.tap(find.text('Corner Cafe'));

      expect(taps, 1);
    });
  });
}
