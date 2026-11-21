import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/core/utils/currency.dart';
import 'package:smart_expense_tracker/features/insights/domain/entities/insight_alert.dart';
import 'package:smart_expense_tracker/features/insights/presentation/widgets/alerts_section.dart';

void main() {
  String? dismissed;

  Future<void> show(WidgetTester tester, List<InsightAlert> alerts) {
    dismissed = null;
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AlertsSection(
            alerts: alerts,
            categoryNames: const {'food': 'Food'},
            currency: Currency.kes,
            onDismiss: (id) => dismissed = id,
          ),
        ),
      ),
    );
  }

  const duplicate = InsightAlert(
    id: 'dup:1',
    kind: AlertKind.possibleDuplicate,
    categoryId: 'food',
    amountMinor: 50000,
    vendor: 'Naivas',
  );
  const large = InsightAlert(
    id: 'big:2',
    kind: AlertKind.unusuallyLarge,
    categoryId: 'food',
    amountMinor: 200000,
    vendor: 'Naivas',
    usualMinor: 50000,
  );
  const high = InsightAlert(
    id: 'cat:food:2026-11',
    kind: AlertKind.categoryAboveNormal,
    categoryId: 'food',
    amountMinor: 200000,
    usualMinor: 100000,
  );

  testWidgets('shows nothing when there are no alerts', (tester) async {
    await show(tester, const []);

    expect(find.byType(Card), findsNothing);
  });

  testWidgets('says what each kind of alert found', (tester) async {
    await show(tester, const [duplicate, large, high]);

    expect(find.text('Possible duplicate'), findsOneWidget);
    expect(find.textContaining('twice within a day'), findsOneWidget);
    expect(find.text('Unusually large expense'), findsOneWidget);
    expect(find.textContaining('the usual'), findsOneWidget);
    expect(find.text('Food is running high'), findsOneWidget);
  });

  testWidgets('closing an alert reports which one', (tester) async {
    await show(tester, const [duplicate, large]);

    await tester.tap(find.byTooltip('Dismiss').last);

    expect(dismissed, 'big:2');
  });
}
