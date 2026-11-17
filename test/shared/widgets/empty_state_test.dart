import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/shared/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState shows the icon, title and message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Nothing here',
            message: 'Add something to get started.',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Add something to get started.'), findsOneWidget);
  });
}
