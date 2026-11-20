import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/result.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/recurring/domain/entities/recurrence_frequency.dart';
import 'package:smart_expense_tracker/features/recurring/domain/entities/recurring_draft.dart';
import 'package:smart_expense_tracker/features/recurring/domain/entities/recurring_rule.dart';
import 'package:smart_expense_tracker/features/recurring/domain/usecases/generate_due_expenses.dart';
import 'package:smart_expense_tracker/features/recurring/domain/usecases/save_recurring_rule.dart';
import 'package:smart_expense_tracker/features/recurring/domain/validation/recurring_checks.dart';

import '../../../support/fakes.dart';

RecurringRule buildRule({
  String id = 'rule1',
  String title = '',
  String vendor = 'Netflix',
  int amountMinor = 120000,
  String categoryId = 'bills',
  RecurrenceFrequency frequency = RecurrenceFrequency.monthly,
  DateTime? anchor,
  DateTime? nextDue,
  bool isActive = true,
}) {
  final due = nextDue ?? DateTime(2026, 11, 1);
  return RecurringRule(
    id: id,
    title: title,
    vendor: vendor,
    amountMinor: amountMinor,
    categoryId: categoryId,
    frequency: frequency,
    anchor: anchor ?? due,
    nextDue: due,
    isActive: isActive,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );
}

void main() {
  final today = DateTime(2026, 11, 20, 14, 30);

  group('GenerateDueExpenses', () {
    late FakeRecurringRepository repository;
    var counter = 0;

    GenerateDueExpenses generator() => GenerateDueExpenses(
      repository,
      now: () => today,
      newId: () => 'expense${++counter}',
    );

    setUp(() => counter = 0);

    test('adds an expense for a date that is due', () async {
      repository = FakeRecurringRepository(
        initial: [buildRule(title: 'Family plan')],
      );

      final added = await generator()();

      expect(added, 1);
      final expense = repository.recorded.single;
      expect(expense.date, DateTime(2026, 11, 1));
      expect(expense.vendor, 'Netflix');
      expect(expense.title, 'Family plan');
      expect(expense.amountMinor, 120000);
      expect(expense.categoryId, 'bills');
    });

    test('marks the expense with the rule that added it', () async {
      repository = FakeRecurringRepository(initial: [buildRule(id: 'r9')]);

      await generator()();

      expect(repository.recorded.single.recurringRuleId, 'r9');
    });

    test('moves the rule on to its next date', () async {
      repository = FakeRecurringRepository(initial: [buildRule()]);

      await generator()();

      expect(repository.rules.single.nextDue, DateTime(2026, 12, 1));
    });

    test('does nothing for a date still ahead', () async {
      repository = FakeRecurringRepository(
        initial: [buildRule(nextDue: DateTime(2026, 11, 21))],
      );

      expect(await generator()(), 0);
      expect(repository.recorded, isEmpty);
      expect(repository.rules.single.nextDue, DateTime(2026, 11, 21));
    });

    test('adds today\'s date, whatever the time of day', () async {
      repository = FakeRecurringRepository(
        initial: [buildRule(nextDue: DateTime(2026, 11, 20))],
      );

      expect(await generator()(), 1);
    });

    test('skips a paused rule, and leaves its date alone', () async {
      repository = FakeRecurringRepository(
        initial: [buildRule(isActive: false)],
      );

      expect(await generator()(), 0);
      expect(repository.rules.single.nextDue, DateTime(2026, 11, 1));
    });

    test('catches up on every date missed while the app was closed', () async {
      repository = FakeRecurringRepository(
        initial: [buildRule(nextDue: DateTime(2026, 8, 1))],
      );

      final added = await generator()();

      expect(added, 4);
      expect(repository.recorded.map((e) => e.date), [
        DateTime(2026, 8, 1),
        DateTime(2026, 9, 1),
        DateTime(2026, 10, 1),
        DateTime(2026, 11, 1),
      ]);
    });

    test('running it again straight away adds nothing more', () async {
      repository = FakeRecurringRepository(
        initial: [buildRule(nextDue: DateTime(2026, 9, 1))],
      );

      await generator()();
      final second = await generator()();

      expect(second, 0);
      expect(repository.recorded, hasLength(3));
    });

    test('gives every expense its own id', () async {
      repository = FakeRecurringRepository(
        initial: [buildRule(nextDue: DateTime(2026, 9, 1))],
      );

      await generator()();

      final ids = repository.recorded.map((e) => e.id).toSet();
      expect(ids, hasLength(3));
    });

    test('handles several rules on their own', () async {
      repository = FakeRecurringRepository(
        initial: [
          buildRule(id: 'a', vendor: 'Rent', nextDue: DateTime(2026, 11, 5)),
          buildRule(id: 'b', vendor: 'Gym', nextDue: DateTime(2026, 12, 5)),
          buildRule(
            id: 'c',
            vendor: 'Water',
            frequency: RecurrenceFrequency.weekly,
            nextDue: DateTime(2026, 11, 10),
          ),
        ],
      );

      final added = await generator()();

      // Rent once, Gym not yet, Water on the 10th and the 17th.
      expect(added, 3);
      expect(repository.recorded.map((e) => e.vendor).toSet(), {
        'Rent',
        'Water',
      });
    });

    test(
      'a rule that cannot be saved is left as it was, and others go on',
      () async {
        repository = FakeRecurringRepository(
          initial: [
            buildRule(id: 'a', vendor: 'Rent'),
            buildRule(id: 'b', vendor: 'Gym'),
          ],
        );
        var calls = 0;
        final broken = _FailsOnce(repository, () => calls++ == 0);

        final added = await GenerateDueExpenses(
          broken,
          now: () => today,
          newId: () => 'x${++counter}',
        )();

        expect(added, 1);
        expect(repository.recorded.single.vendor, 'Gym');
        // The one that failed is still due, so it is tried again next time.
        expect(
          repository.rules.firstWhere((r) => r.id == 'a').nextDue,
          DateTime(2026, 11, 1),
        );
      },
    );

    test('does not crash when the rules cannot be read', () async {
      repository = FakeRecurringRepository(initial: [buildRule()])
        ..readError = const StorageException('x');

      expect(await generator()(), 0);
    });

    test('does nothing without any rules', () async {
      repository = FakeRecurringRepository();

      expect(await generator()(), 0);
    });
  });

  group('SaveRecurringRule', () {
    late FakeRecurringRepository repository;
    late SaveRecurringRule save;

    RecurringDraft draft({
      String title = '',
      String vendor = 'Netflix',
      int? amountMinor = 120000,
      String? categoryId = 'bills',
      RecurrenceFrequency frequency = RecurrenceFrequency.monthly,
      DateTime? nextDue,
      bool isActive = true,
    }) => RecurringDraft(
      title: title,
      vendor: vendor,
      amountMinor: amountMinor,
      categoryId: categoryId,
      frequency: frequency,
      nextDue: nextDue ?? DateTime(2026, 12, 1),
      isActive: isActive,
    );

    String? errorFor(Result<RecurringRule> result, String field) =>
        ((result as Failure<RecurringRule>).failure as ValidationFailure)
            .fieldErrors[field];

    setUp(() {
      repository = FakeRecurringRepository();
      save = SaveRecurringRule(
        repository,
        now: () => today,
        newId: () => 'new1',
      );
    });

    test('saves a new rule, counted from the date chosen', () async {
      final result = await save(draft(nextDue: DateTime(2026, 12, 31, 18)));

      final rule = (result as Success<RecurringRule>).value;
      expect(rule.id, 'new1');
      expect(rule.nextDue, DateTime(2026, 12, 31));
      expect(rule.anchor, DateTime(2026, 12, 31));
      expect(repository.rules.single, rule);
    });

    test('cleans the note, and a blank vendor becomes Unknown', () async {
      final result = await save(draft(title: '  Family plan ', vendor: ' '));

      final rule = (result as Success<RecurringRule>).value;
      expect(rule.title, 'Family plan');
      expect(rule.vendor, 'Unknown');
    });

    test('a note alone is enough as a name', () async {
      final result = await save(draft(title: 'Rent', vendor: ''));

      expect(result, isA<Success<RecurringRule>>());
    });

    group('editing', () {
      final original = buildRule(
        id: 'r1',
        anchor: DateTime(2026, 1, 31),
        nextDue: DateTime(2026, 2, 28),
      );

      test('keeps the id and the time it was created', () async {
        final result = await save(
          draft(nextDue: DateTime(2026, 2, 28), amountMinor: 99900),
          original: original,
        );

        final rule = (result as Success<RecurringRule>).value;
        expect(rule.id, 'r1');
        expect(rule.createdAt, original.createdAt);
        expect(rule.amountMinor, 99900);
      });

      test('keeps the anchor when the date is left alone', () async {
        final result = await save(
          draft(nextDue: DateTime(2026, 2, 28)),
          original: original,
        );

        // Still counted from the 31st, so the next one is 31 March.
        expect(
          (result as Success<RecurringRule>).value.anchor,
          DateTime(2026, 1, 31),
        );
      });

      test('counts from the new date when the user changes it', () async {
        final result = await save(
          draft(nextDue: DateTime(2026, 12, 15)),
          original: original,
        );

        expect(
          (result as Success<RecurringRule>).value.anchor,
          DateTime(2026, 12, 15),
        );
      });

      test('can pause a rule', () async {
        final result = await save(
          draft(nextDue: DateTime(2026, 2, 28), isActive: false),
          original: original,
        );

        expect((result as Success<RecurringRule>).value.isActive, isFalse);
      });
    });

    group('refuses', () {
      test(
        'no name at all: it needs a note or a vendor to be called',
        () async {
          final result = await save(draft(title: ' ', vendor: ' '));

          expect(
            errorFor(result, RecurringField.name),
            RecurringError.nameRequired,
          );
        },
      );

      test('a note or vendor that is too long', () async {
        final result = await save(draft(vendor: 'x' * 61));

        expect(
          errorFor(result, RecurringField.name),
          RecurringError.nameTooLong,
        );
      });

      test('a missing amount, and tells blank from not a number', () async {
        final blank = await save(draft(amountMinor: null), amountText: '');
        final text = await save(draft(amountMinor: null), amountText: 'abc');

        expect(
          errorFor(blank, RecurringField.amount),
          RecurringError.amountRequired,
        );
        expect(
          errorFor(text, RecurringField.amount),
          RecurringError.amountInvalid,
        );
      });

      test('zero or more than allowed', () async {
        final zero = await save(draft(amountMinor: 0));
        final huge = await save(draft(amountMinor: 100000000001));

        expect(
          errorFor(zero, RecurringField.amount),
          RecurringError.amountMustBePositive,
        );
        expect(
          errorFor(huge, RecurringField.amount),
          RecurringError.amountTooLarge,
        );
      });

      test('no category', () async {
        final none = await save(draft(categoryId: null));
        final empty = await save(draft(categoryId: ''));

        expect(
          errorFor(none, RecurringField.category),
          RecurringError.categoryRequired,
        );
        expect(
          errorFor(empty, RecurringField.category),
          RecurringError.categoryRequired,
        );
      });

      test(
        'a first date more than a year back, but not exactly a year',
        () async {
          // Today is 20 Nov 2026, and 366 days back is 19 Nov 2025.
          final ok = await save(draft(nextDue: DateTime(2025, 11, 19)));
          final tooOld = await save(draft(nextDue: DateTime(2025, 11, 18)));

          expect(ok, isA<Success<RecurringRule>>());
          expect(
            errorFor(tooOld, RecurringField.date),
            RecurringError.dateTooOld,
          );
        },
      );

      test('a first date too far ahead', () async {
        final result = await save(draft(nextDue: DateTime(2036, 1, 1)));

        expect(
          errorFor(result, RecurringField.date),
          RecurringError.dateTooFar,
        );
      });

      test('and saves nothing when it refuses', () async {
        await save(draft(amountMinor: 0));

        expect(repository.rules, isEmpty);
      });
    });

    test('reports a storage failure', () async {
      repository.saveError = const StorageException('x');

      final result = await save(draft());

      expect(
        (result as Failure<RecurringRule>).failure,
        const StorageFailure(),
      );
    });
  });

  group('monthly cost', () {
    test('is the amount for a monthly rule', () {
      expect(buildRule(amountMinor: 100000).monthlyCostMinor, 100000);
    });

    test('is a twelfth for a yearly rule', () {
      expect(
        buildRule(
          amountMinor: 1200000,
          frequency: RecurrenceFrequency.yearly,
        ).monthlyCostMinor,
        100000,
      );
    });

    test('is 52 weeks over 12 months for a weekly rule', () {
      expect(
        buildRule(
          amountMinor: 1000,
          frequency: RecurrenceFrequency.weekly,
        ).monthlyCostMinor,
        4333,
      );
    });
  });
}

/// A repository whose `recordOccurrences` fails when told to, then works.
class _FailsOnce extends FakeRecurringRepository {
  _FailsOnce(FakeRecurringRepository inner, this._shouldFail)
    : _inner = inner,
      super(initial: inner.rules);

  final FakeRecurringRepository _inner;
  final bool Function() _shouldFail;

  @override
  Future<void> recordOccurrences(RecurringRule rule, expenses) async {
    if (_shouldFail()) throw const StorageException('x');
    await _inner.recordOccurrences(rule, expenses);
  }
}
