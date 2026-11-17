import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/shared/widgets/app_logo.dart';

void main() {
  Widget host(ThemeData theme, double size) => MaterialApp(
    theme: theme,
    home: Scaffold(
      body: Center(child: AppLogo(size: size)),
    ),
  );

  testWidgets('AppLogo takes the requested size', (tester) async {
    await tester.pumpWidget(host(AppTheme.light, 80));

    expect(tester.getSize(find.byType(AppLogo)), const Size.square(80));
  });

  testWidgets('AppLogo draws in both light and dark themes', (tester) async {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await tester.pumpWidget(host(theme, 96));

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('SpendWise IQ logo'), findsOneWidget);
    }
  });
}
