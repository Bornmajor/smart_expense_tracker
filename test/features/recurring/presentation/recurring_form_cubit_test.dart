import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/recurring/domain/entities/recurrence_frequency.dart';
import 'package:smart_expense_tracker/features/recurring/domain/usecases/generate_due_expenses.dart';
import 'package:smart_expense_tracker/features/recurring/domain/usecases/save_recurring_rule.dart';
import 'package:smart_expense_tracker/features/recurring/domain/validation/recurring_checks.dart';
import 'package:smart_expense_tracker/features/recurring/presentation/cubit/recurring_form_cubit.dart';
import 'package:smart_expense_tracker/features/recurring/presentation/cubit/recurring_form_state.dart';
import 'package:smart_expense_tracker/features/recurring/presentation/cubit/recurring_state.dart';
import 'package:smart_expense_tracker/features/recurring/presentation/recurring_messages.dart';

import '../../../support/fakes.dart';
import '../domain/recurring_logic_test.dart' show buildRule;

void main() {
  final now = DateTime(2026, 11, 20, 10);
  late FakeRecurringRepository repository;

  RecurringFormCubit cubitFor({bool editing = false}) {
    final cubit = RecurringFormCubit(
      saveRule: SaveRecurringRule(repository, now: () => now),
      repository: repository,
      generateDue: GenerateDueExpenses(repository, now: () => now),
      original: editing ? buildRule() : null,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<void> submit(
    RecurringFormCubit cubit, {
    String amount = '1200',
    DateTime? nextDue,
    String? categoryId = 'bills',
  }) => cubit.submit(
    vendor: 'Netflix',
    amountText: amount,
    categoryId: categoryId,
    frequency: RecurrenceFrequency.monthly,
    nextDue: nextDue ?? DateTime(2026, 12, 1),
  );

  setUp(() => repository = FakeRecurringRepository());

  test(
    'saves a rule that starts in the future, and adds nothing yet',
    () async {
      final cubit = cubitFor();

      await submit(cubit);

      expect(cubit.state.status, RecurringFormStatus.saved);
      expect(cubit.state.addedCount, 0);
      expect(repository.rules, hasLength(1));
    },
  );

  test('adds an expense straight away when the date is already due', () async {
    final cubit = cubitFor();

    await submit(cubit, nextDue: DateTime(2026, 11, 20));

    expect(cubit.state.status, RecurringFormStatus.saved);
    expect(cubit.state.addedCount, 1);
    expect(repository.recorded.single.date, DateTime(2026, 11, 20));
  });

  test('adds every missed expense when the date was in the past', () async {
    final cubit = cubitFor();

    await submit(cubit, nextDue: DateTime(2026, 9, 1));

    expect(cubit.state.addedCount, 3);
  });

  test('shows what is wrong with a field, and saves nothing', () async {
    final cubit = cubitFor();

    await submit(cubit, amount: '0', categoryId: null);

    expect(cubit.state.status, RecurringFormStatus.editing);
    expect(
      cubit.state.fieldErrors.keys,
      containsAll([RecurringField.amount, RecurringField.category]),
    );
    expect(repository.rules, isEmpty);
  });

  test('says the amount is not a number, not that it is missing', () async {
    final cubit = cubitFor();

    await submit(cubit, amount: 'abc');

    expect(
      cubit.state.fieldErrors[RecurringField.amount],
      RecurringError.amountInvalid,
    );
  });

  test('reports a storage failure', () async {
    repository.saveError = const StorageException('x');
    final cubit = cubitFor();

    await submit(cubit);

    expect(cubit.state.status, RecurringFormStatus.failed);
    expect(cubit.state.failure, const StorageFailure());
  });

  test('ignores a second save while one is running', () async {
    final cubit = cubitFor();

    final first = submit(cubit);
    await submit(cubit);
    await first;

    expect(repository.rules, hasLength(1));
  });

  group('editing', () {
    test('deletes the rule', () async {
      repository = FakeRecurringRepository(initial: [buildRule()]);
      final cubit = cubitFor(editing: true);

      await cubit.delete();

      expect(cubit.state.status, RecurringFormStatus.deleted);
      expect(repository.rules, isEmpty);
    });

    test('does nothing to delete when adding', () async {
      repository = FakeRecurringRepository(initial: [buildRule()]);
      final cubit = cubitFor();

      await cubit.delete();

      expect(cubit.state.status, RecurringFormStatus.editing);
      expect(repository.rules, hasLength(1));
    });
  });

  group('the list state', () {
    test('adds up what active rules cost in a month', () {
      final state = RecurringLoaded([
        buildRule(amountMinor: 100000),
        buildRule(
          id: 'yearly',
          amountMinor: 1200000,
          frequency: RecurrenceFrequency.yearly,
        ),
        buildRule(id: 'paused', amountMinor: 999999, isActive: false),
      ]);

      // 1,000 monthly + 12,000 a year / 12; the paused rule is left out.
      expect(state.monthlyCostMinor, 200000);
    });
  });

  group('messages', () {
    test('every error code has its own text', () {
      final codes = [
        RecurringError.nameRequired,
        RecurringError.nameTooLong,
        RecurringError.amountRequired,
        RecurringError.amountInvalid,
        RecurringError.amountMustBePositive,
        RecurringError.amountTooLarge,
        RecurringError.categoryRequired,
        RecurringError.dateTooOld,
        RecurringError.dateTooFar,
      ];

      expect({for (final c in codes) recurringErrorMessage(c)}, hasLength(9));
    });
  });
}
