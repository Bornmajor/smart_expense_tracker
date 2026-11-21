import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/core/utils/currency.dart';
import 'package:smart_expense_tracker/features/currency_conversion/domain/entities/exchange_rates.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/widgets/currency_converter.dart';

void main() {
  final rates = ExchangeRates(
    perUsd: const {'USD': 1, 'KES': 129},
    fetchedAt: DateTime(2026, 11, 20),
  );

  Future<void> show(
    WidgetTester tester, {
    Currency? from,
    ExchangeRates? rates,
    String amount = '',
    DateTime? now,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: CurrencyConverter(
          appCurrency: Currency.kes,
          from: from,
          rates: rates,
          amountText: amount,
          onChoose: () {},
          onClear: () {},
          now: () => now ?? DateTime(2026, 11, 21),
        ),
      ),
    ),
  );

  testWidgets('closed, it is one quiet link', (tester) async {
    await show(tester);

    expect(find.text('Different currency?'), findsOneWidget);
    expect(find.text('USD'), findsNothing);
  });

  testWidgets('open, it shows the converted amount and the rate date', (
    tester,
  ) async {
    await show(tester, from: Currency.usd, rates: rates, amount: '100');

    expect(find.text('USD'), findsOneWidget);
    expect(find.textContaining('12,900.00'), findsOneWidget);
    expect(find.text('Rate from 20 Nov'), findsOneWidget);
  });

  testWidgets('warns when the rate is old', (tester) async {
    await show(
      tester,
      from: Currency.usd,
      rates: rates,
      amount: '100',
      now: DateTime(2026, 12, 5),
    );

    expect(find.textContaining('may be out of date'), findsOneWidget);
  });

  testWidgets('says so when no rates were ever downloaded', (tester) async {
    await show(tester, from: Currency.usd, amount: '100');

    expect(find.textContaining('not downloaded yet'), findsOneWidget);
    expect(find.textContaining('='), findsNothing);
  });

  testWidgets('shows no result until an amount is typed', (tester) async {
    await show(tester, from: Currency.usd, rates: rates);

    expect(find.textContaining('='), findsNothing);
    expect(find.text('Rate from 20 Nov'), findsOneWidget);
  });
}
