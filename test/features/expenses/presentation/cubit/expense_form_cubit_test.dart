import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:smart_expense_tracker/features/expenses/domain/usecases/save_expense.dart';
import 'package:smart_expense_tracker/features/expenses/domain/usecases/update_expense.dart';
import 'package:smart_expense_tracker/features/expenses/domain/validation/expense_validation.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/cubit/expense_form_cubit.dart';
import 'package:smart_expense_tracker/features/expenses/presentation/cubit/expense_form_state.dart';

import '../../../../support/builders.dart';
import '../../../../support/fakes.dart';

void main() {
  late FakeExpenseRepository repository;
  final today = DateTime(2026, 11, 17);
  final clock = DateTime(2026, 11, 17, 9);

  ExpenseFormCubit buildCubit({Expense? original}) => ExpenseFormCubit(
    saveExpense: SaveExpense(repository, now: () => clock),
    updateExpense: UpdateExpense(repository, now: () => clock),
    repository: repository,
    original: original,
  );

  setUp(() => repository = FakeExpenseRepository());

  group('ExpenseFormCubit adding', () {
    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'saves a valid expense and ends in the saved state',
      build: buildCubit,
      act: (cubit) => cubit.submit(
        vendor: 'Shell',
        amountText: '45.20',
        date: today,
        categoryId: 'transport',
      ),
      expect: () => const [
        ExpenseFormState(status: ExpenseFormStatus.saving),
        ExpenseFormState(status: ExpenseFormStatus.saved),
      ],
      verify: (_) {
        expect(repository.saved.single.amountMinor, 4520);
        expect(repository.saved.single.vendor, 'Shell');
      },
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'saves the title with the expense',
      build: buildCubit,
      act: (cubit) => cubit.submit(
        title: 'Team lunch',
        vendor: 'Cafe',
        amountText: '9',
        date: today,
        categoryId: 'food',
      ),
      verify: (_) => expect(repository.saved.single.title, 'Team lunch'),
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'shows a too-long title as a title error',
      build: buildCubit,
      act: (cubit) => cubit.submit(
        title: 'a' * 61,
        vendor: 'Cafe',
        amountText: '9',
        date: today,
        categoryId: 'food',
      ),
      expect: () => const [
        ExpenseFormState(status: ExpenseFormStatus.saving),
        ExpenseFormState(
          fieldErrors: {ExpenseField.title: ExpenseError.titleTooLong},
        ),
      ],
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'shows field errors from the use case and stays editable',
      build: buildCubit,
      act: (cubit) => cubit.submit(
        vendor: '',
        amountText: '',
        date: today,
        categoryId: null,
      ),
      expect: () => const [
        ExpenseFormState(status: ExpenseFormStatus.saving),
        ExpenseFormState(
          fieldErrors: {
            ExpenseField.amount: ExpenseError.amountRequired,
            ExpenseField.category: ExpenseError.categoryRequired,
          },
        ),
      ],
      verify: (_) => expect(repository.saved, isEmpty),
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'reports text that is not a number as an invalid amount',
      build: buildCubit,
      act: (cubit) => cubit.submit(
        vendor: 'Shell',
        amountText: '1.2.3',
        date: today,
        categoryId: 'transport',
      ),
      expect: () => const [
        ExpenseFormState(status: ExpenseFormStatus.saving),
        ExpenseFormState(
          fieldErrors: {ExpenseField.amount: ExpenseError.amountInvalid},
        ),
      ],
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'ends in the failed state when storage fails',
      build: () {
        repository.saveError = const StorageException('disk full');
        return buildCubit();
      },
      act: (cubit) => cubit.submit(
        vendor: 'Shell',
        amountText: '10',
        date: today,
        categoryId: 'transport',
      ),
      expect: () => const [
        ExpenseFormState(status: ExpenseFormStatus.saving),
        ExpenseFormState(
          status: ExpenseFormStatus.failed,
          failure: StorageFailure(),
        ),
      ],
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'ignores a second submit while saving',
      build: buildCubit,
      act: (cubit) async {
        final first = cubit.submit(
          vendor: 'A',
          amountText: '1',
          date: today,
          categoryId: 'food',
        );
        await cubit.submit(
          vendor: 'B',
          amountText: '2',
          date: today,
          categoryId: 'food',
        );
        await first;
      },
      verify: (_) => expect(repository.saved, hasLength(1)),
    );

    test('is not in editing mode and does nothing on delete', () async {
      final cubit = buildCubit();

      await cubit.delete();

      expect(cubit.isEditing, isFalse);
      expect(cubit.state, const ExpenseFormState());
      await cubit.close();
    });
  });

  group('ExpenseFormCubit editing', () {
    final original = buildExpense(id: 'e1', vendor: 'Shell', amountMinor: 1000);

    setUp(() => repository = FakeExpenseRepository(initial: [original]));

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'updates the original instead of adding a new expense',
      build: () => buildCubit(original: original),
      act: (cubit) => cubit.submit(
        vendor: 'BP',
        amountText: '12.50',
        date: today,
        categoryId: 'transport',
      ),
      expect: () => const [
        ExpenseFormState(status: ExpenseFormStatus.saving),
        ExpenseFormState(status: ExpenseFormStatus.saved),
      ],
      verify: (cubit) {
        expect(cubit.isEditing, isTrue);
        final stored = repository.saved.single;
        expect(stored.id, 'e1');
        expect(stored.vendor, 'BP');
        expect(stored.amountMinor, 1250);
      },
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'keeps the same rules as adding',
      build: () => buildCubit(original: original),
      act: (cubit) => cubit.submit(
        vendor: 'BP',
        amountText: '0',
        date: today,
        categoryId: 'transport',
      ),
      expect: () => const [
        ExpenseFormState(status: ExpenseFormStatus.saving),
        ExpenseFormState(
          fieldErrors: {ExpenseField.amount: ExpenseError.amountMustBePositive},
        ),
      ],
      verify: (_) => expect(repository.saved.single, original),
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'deletes the expense',
      build: () => buildCubit(original: original),
      act: (cubit) => cubit.delete(),
      expect: () => const [
        ExpenseFormState(status: ExpenseFormStatus.deleting),
        ExpenseFormState(status: ExpenseFormStatus.deleted),
      ],
      verify: (_) => expect(repository.saved, isEmpty),
    );

    blocTest<ExpenseFormCubit, ExpenseFormState>(
      'ends in the failed state when deleting fails',
      build: () {
        repository.deleteError = const StorageException('disk full');
        return buildCubit(original: original);
      },
      act: (cubit) => cubit.delete(),
      expect: () => const [
        ExpenseFormState(status: ExpenseFormStatus.deleting),
        ExpenseFormState(
          status: ExpenseFormStatus.failed,
          failure: StorageFailure(),
        ),
      ],
      verify: (_) => expect(repository.saved, [original]),
    );
  });
}
