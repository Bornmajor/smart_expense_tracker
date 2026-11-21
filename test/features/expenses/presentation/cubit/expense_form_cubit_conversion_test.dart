import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/currency_conversion/domain/entities/exchange_rates.dart';
import 'package:smart_expense_tracker/features/expenses/domain/usecases/save_expense.dart';
import 'package:smart_expense_tracker/features/expenses/domain/usecases/update_expense.dart';
import 'package:smart_expense_tracker/features/expenses/domain/validation/expense_validation.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/cubit/expense_form_cubit.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/cubit/expense_form_state.dart';
import 'package:smart_expense_tracker/features/recurring/domain/entities/recurrence_frequency.dart';
import 'package:smart_expense_tracker/features/recurring/domain/usecases/save_repeating_expense.dart';

import '../../../../support/builders.dart';
import '../../../../support/fakes.dart';

void main() {
  late FakeExpenseRepository repository;
  late FakeRecurringRepository recurring;
  late FakeExchangeRateRepository rates;
  final today = DateTime(2026, 11, 17);
  final clock = DateTime(2026, 11, 17, 9);

  ExpenseFormCubit buildCubit() => ExpenseFormCubit(
    saveExpense: SaveExpense(repository, now: () => clock),
    updateExpense: UpdateExpense(repository, now: () => clock),
    saveRepeating: SaveRepeatingExpense(recurring, now: () => clock),
    rates: rates,
    repository: repository,
  );

  setUp(() {
    repository = FakeExpenseRepository();
    recurring = FakeRecurringRepository();
    rates = FakeExchangeRateRepository(
      ExchangeRates(
        perUsd: const {'USD': 1, 'KES': 129},
        fetchedAt: DateTime(2026, 11, 17),
      ),
    );
  });

  Future<void> submit(
    ExpenseFormCubit cubit, {
    String amount = '100',
    String? from = 'USD',
  }) => cubit.submit(
    vendor: 'Amazon',
    amountText: amount,
    date: today,
    categoryId: 'shopping',
    fromCurrency: from,
    toCurrency: 'KES',
  );

  test('saves the converted amount and keeps what was paid', () async {
    final cubit = buildCubit();

    await submit(cubit);

    final saved = repository.saved.single;
    expect(saved.amountMinor, 1290000);
    expect(saved.originalAmountMinor, 10000);
    expect(saved.originalCurrency, 'USD');
    expect(cubit.state.status, ExpenseFormStatus.saved);
  });

  test('without another currency nothing is converted', () async {
    final cubit = buildCubit();

    await submit(cubit, amount: '100', from: null);

    final saved = repository.saved.single;
    expect(saved.amountMinor, 10000);
    expect(saved.originalAmountMinor, isNull);
    expect(saved.originalCurrency, isNull);
  });

  test('asks for rates instead of saving when none were downloaded', () async {
    rates.rates = null;
    final cubit = buildCubit();

    await submit(cubit);

    expect(repository.saved, isEmpty);
    expect(cubit.state.status, ExpenseFormStatus.editing);
    expect(
      cubit.state.fieldErrors[ExpenseField.amount],
      ExpenseError.ratesUnavailable,
    );
  });

  test('a currency with no rate is reported the same way', () async {
    final cubit = buildCubit();

    await submit(cubit, from: 'XYZ');

    expect(repository.saved, isEmpty);
    expect(
      cubit.state.fieldErrors[ExpenseField.amount],
      ExpenseError.ratesUnavailable,
    );
  });

  test('a bad amount is still reported as a bad amount', () async {
    final cubit = buildCubit();

    await submit(cubit, amount: 'abc');

    expect(repository.saved, isEmpty);
    expect(
      cubit.state.fieldErrors[ExpenseField.amount],
      ExpenseError.amountInvalid,
    );
  });

  test('a repeating expense repeats the converted amount', () async {
    final cubit = buildCubit();

    await cubit.submit(
      vendor: 'Netflix',
      amountText: '10',
      date: today,
      categoryId: 'bills',
      fromCurrency: 'USD',
      toCurrency: 'KES',
      repeat: RecurrenceFrequency.monthly,
    );

    expect(recurring.rules.single.amountMinor, 129000);
    expect(recurring.created.single.originalCurrency, 'USD');
  });

  group('editing a converted expense', () {
    final converted = buildExpense(
      amountMinor: 1290000,
      originalAmountMinor: 10000,
      originalCurrency: 'USD',
    );

    test('keeps what was paid while the amount is unchanged', () async {
      final cubit = ExpenseFormCubit(
        saveExpense: SaveExpense(repository, now: () => clock),
        updateExpense: UpdateExpense(repository, now: () => clock),
        saveRepeating: SaveRepeatingExpense(recurring, now: () => clock),
        rates: rates,
        repository: repository,
        original: converted,
      );

      await cubit.submit(
        vendor: 'Amazon',
        amountText: '12900.00',
        date: converted.date,
        categoryId: converted.categoryId,
      );

      expect(repository.saved.single.originalAmountMinor, 10000);
      expect(repository.saved.single.originalCurrency, 'USD');
    });

    test('forgets it when the amount is changed', () async {
      final cubit = ExpenseFormCubit(
        saveExpense: SaveExpense(repository, now: () => clock),
        updateExpense: UpdateExpense(repository, now: () => clock),
        saveRepeating: SaveRepeatingExpense(recurring, now: () => clock),
        rates: rates,
        repository: repository,
        original: converted,
      );

      await cubit.submit(
        vendor: 'Amazon',
        amountText: '13000',
        date: converted.date,
        categoryId: converted.categoryId,
      );

      expect(repository.saved.single.amountMinor, 1300000);
      expect(repository.saved.single.originalAmountMinor, isNull);
      expect(repository.saved.single.originalCurrency, isNull);
    });
  });
}
