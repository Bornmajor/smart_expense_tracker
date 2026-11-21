import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_expense_tracker/app/app_routes.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/shared/widgets/empty_state.dart';

import '../support/pump_app.dart';

/// Every empty screen keeps its words centered, even when a title wraps on a
/// narrow phone.
void main() {
  const narrow = Size(320, 640);

  double centerX(WidgetTester tester, Finder finder) =>
      tester.getCenter(finder).dx;

  /// The text is a block centered on the screen, and its lines are centered
  /// within the block.
  void expectCentered(WidgetTester tester, Finder finder) {
    expect(centerX(tester, finder), closeTo(narrow.width / 2, 1));
    expect(tester.widget<Text>(finder).textAlign, TextAlign.center);
  }

  testWidgets('the EmptyState widget centers a long title that wraps', (
    tester,
  ) async {
    tester.view.physicalSize = narrow;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: EmptyState(
            icon: Icons.pie_chart_outline,
            title: 'No expenses in November 2026 at all so far',
            message: 'Add an expense and it shows up here.',
          ),
        ),
      ),
    );

    final title = find.text('No expenses in November 2026 at all so far');
    expectCentered(tester, title);
    // It really did wrap, so the lines matter.
    expect(tester.getSize(title).height, greaterThan(30));
    expectCentered(tester, find.text('Add an expense and it shows up here.'));
    expect(
      centerX(tester, find.byIcon(Icons.pie_chart_outline)),
      closeTo(160, 1),
    );
  });

  testWidgets('the Summary with no expenses is centered', (tester) async {
    await pumpRouterApp(tester, screenSize: narrow);
    await goToTab(tester, 'Summary');

    final title = find.textContaining('No expenses in ');
    expect(title, findsOneWidget);
    expectCentered(tester, title);
  });

  testWidgets('the expense list with no expenses is centered', (tester) async {
    await pumpRouterApp(tester, screenSize: narrow);

    expectCentered(tester, find.text('Add your first expense'));
  });

  testWidgets('the recurring list with nothing in it is centered', (
    tester,
  ) async {
    await pumpRouterApp(tester, screenSize: narrow);
    final context = tester.element(find.byType(Scaffold).first);
    GoRouter.of(context).push(AppRoutes.recurring);
    await tester.pumpAndSettle();

    expectCentered(tester, find.text('Nothing repeats yet'));
  });

  testWidgets('the Home welcome for a new app is centered', (tester) async {
    await pumpRouterApp(tester, screenSize: narrow, startOnHome: true);

    expectCentered(tester, find.text('Let\'s add your first expense'));
    expectCentered(
      tester,
      find.textContaining('Adding an expense is effortless'),
    );
  });
}
