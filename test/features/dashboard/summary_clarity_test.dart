import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/core/utils/currency.dart';
import 'package:smart_expense_tracker/core/utils/money.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget_progress.dart';
import 'package:smart_expense_tracker/features/dashboard/presentation/widgets/budget_section.dart';
import 'package:smart_expense_tracker/features/dashboard/presentation/widgets/category_breakdown_tile.dart';

Widget host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

BudgetProgress progress(String scope, int limit, int spent) => BudgetProgress(
  budget: Budget(scopeId: scope, limitMinor: limit),
  spentMinor: spent,
);

void main() {
  group('whole units for a quick look', () {
    test('Money.formatWhole rounds to the nearest unit', () {
      expect(Money.formatWhole(2894609), '28,946');
      expect(Money.formatWhole(2894650), '28,947');
      expect(Money.formatWhole(49), '0');
      expect(Money.formatWhole(50), '1');
      expect(Money.formatWhole(-2894609), '-28,946');
      expect(Money.formatWhole(0), '0');
    });

    test('big amounts drop their cents', () {
      expect(Currency.kes.formatGlance(2894609), 'KSh 28,946');
      expect(Currency.kes.formatGlance(3000000), 'KSh 30,000');
      expect(Currency.kes.formatGlance(100000), 'KSh 1,000');
    });

    test('small amounts keep their cents, unless there are none', () {
      expect(Currency.kes.formatGlance(45050), 'KSh 450.50');
      expect(Currency.kes.formatGlance(99999), 'KSh 999.99');
      expect(Currency.kes.formatGlance(35000), 'KSh 350');
    });

    test('works with a sign symbol, no symbol and negative amounts', () {
      expect(Currency.usd.formatGlance(1234567), r'$12,346');
      expect(Currency.none.formatGlance(1234567), '12,346');
      expect(Currency.kes.formatGlance(-250000), '-KSh 2,500');
    });

    test('the exact format is unchanged for lists and exports', () {
      expect(Currency.kes.format(2894609), 'KSh 28,946.09');
    });
  });

  group('a category card has one bar, and says what it is', () {
    Widget tile({BudgetProgress? budget, double share = 1}) => host(
      CategoryBreakdownTile(
        name: 'Bills',
        totalMinor: 105391,
        share: share,
        currency: Currency.kes,
        onTap: () {},
        budget: budget,
      ),
    );

    testWidgets('without a budget the bar is labelled as a share', (
      tester,
    ) async {
      await tester.pumpWidget(tile());

      expect(find.text('100% of spending'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('left'), findsNothing);
    });

    testWidgets('with a budget the bar is the budget, not the share', (
      tester,
    ) async {
      await tester.pumpWidget(tile(budget: progress('bills', 2500000, 105391)));

      expect(find.textContaining('of spending'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.textContaining('KSh 23,946 left'), findsOneWidget);
      expect(find.textContaining('of KSh 25,000 budget'), findsOneWidget);
      // Whole shillings at a glance.
      expect(find.text('KSh 1,054'), findsOneWidget);
    });

    testWidgets('past its budget it says how much over', (tester) async {
      await tester.pumpWidget(tile(budget: progress('bills', 100000, 351000)));

      expect(find.textContaining('KSh 2,510 over'), findsOneWidget);
      expect(find.textContaining('budget KSh 1,000'), findsOneWidget);
    });
  });

  group('the Budgets block lists only the overall budget', () {
    Widget section(List<BudgetProgress> list) => host(
      BudgetSection(progress: list, currency: Currency.kes, onOpen: (_) {}),
    );

    testWidgets('a category budget is not listed again', (tester) async {
      await tester.pumpWidget(
        section([
          progress(Budget.overallId, 3000000, 105391),
          progress('bills', 2500000, 105391),
        ]),
      );

      expect(find.text('All spending'), findsOneWidget);
      expect(find.text('Bills'), findsNothing);
      expect(find.textContaining('KSh 28,946 left'), findsOneWidget);
      expect(find.textContaining('4% used'), findsOneWidget);
    });

    testWidgets('with only category budgets it offers the overall one', (
      tester,
    ) async {
      await tester.pumpWidget(section([progress('bills', 2500000, 105391)]));

      expect(find.text('Set a monthly budget'), findsOneWidget);
      expect(find.text('All spending'), findsNothing);
    });

    testWidgets('with no budget at all it offers to set one', (tester) async {
      await tester.pumpWidget(section(const []));

      expect(find.text('Set a monthly budget'), findsOneWidget);
    });
  });

  testWidgets('the left amount is the bold one, the limit is context', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        BudgetSection(
          progress: [progress(Budget.overallId, 3000000, 105391)],
          currency: Currency.kes,
        ),
      ),
    );

    final rich = tester.widget<RichText>(
      find.byWidgetPredicate(
        (w) =>
            w is RichText && w.text.toPlainText().contains('KSh 28,946 left'),
      ),
    );
    // Text.rich wraps what it is given in one more span.
    final wrapper = (rich.text as TextSpan).children!.single as TextSpan;
    final spans = wrapper.children!.cast<TextSpan>();
    final answer = spans.first.style!;
    final limit = spans.last.style!;
    expect(answer.fontSize! > limit.fontSize!, isTrue);
    expect(answer.fontWeight!.value > limit.fontWeight!.value, isTrue);
  });
}
