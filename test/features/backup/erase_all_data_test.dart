import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expense_tracker/core/database/app_database.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/result.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/backup/data/repositories/shared_preferences_reset.dart';
import 'package:smart_expense_tracker/features/backup/domain/usecases/erase_all_data.dart';
import 'package:smart_expense_tracker/features/backup/presentation/cubit/erase_data_cubit.dart';

import 'backup_fakes.dart';

void main() {
  final day = DateTime(2026, 11, 20);

  group('AppDatabase.eraseAllData', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'pets',
              name: 'Pets',
              createdAt: day,
              updatedAt: day,
            ),
          );
      await db
          .into(db.recurringRules)
          .insert(
            RecurringRulesCompanion.insert(
              id: 'r1',
              vendor: 'Netflix',
              amountMinor: 1000,
              categoryId: 'pets',
              frequency: 'monthly',
              anchor: day,
              nextDue: day,
              createdAt: day,
              updatedAt: day,
            ),
          );
      await db
          .into(db.expenses)
          .insert(
            ExpensesCompanion.insert(
              id: 'e1',
              vendor: 'Vet',
              amountMinor: 5000,
              date: day,
              categoryId: 'pets',
              createdAt: day,
              updatedAt: day,
              recurringRuleId: const Value('r1'),
            ),
          );
      await db
          .into(db.budgets)
          .insert(
            BudgetsCompanion.insert(
              scopeId: '*',
              limitMinor: 100000,
              updatedAt: day,
            ),
          );
    });

    tearDown(() => db.close());

    test(
      'removes everything and brings back the standard categories',
      () async {
        await db.eraseAllData();

        expect(await db.select(db.expenses).get(), isEmpty);
        expect(await db.select(db.recurringRules).get(), isEmpty);
        expect(await db.select(db.budgets).get(), isEmpty);
        final ids = (await db.select(db.categories).get()).map((c) => c.id);
        expect(
          ids,
          unorderedEquals([
            'food',
            'transport',
            'bills',
            'shopping',
            'health',
            'other',
          ]),
        );
      },
    );

    test('leaves the app able to add an expense afterwards', () async {
      await db.eraseAllData();

      await db
          .into(db.expenses)
          .insert(
            ExpensesCompanion.insert(
              id: 'new',
              vendor: 'Cafe',
              amountMinor: 100,
              date: day,
              categoryId: 'other',
              createdAt: day,
              updatedAt: day,
            ),
          );

      expect(await db.select(db.expenses).get(), hasLength(1));
    });
  });

  group('EraseAllData', () {
    late FakeBackupRepository repository;
    late FakeLocalStateReset reset;

    setUp(() {
      repository = FakeBackupRepository();
      reset = FakeLocalStateReset();
    });

    test(
      'erases the data and then forgets everything the app remembers',
      () async {
        final result = await EraseAllData(repository, reset)();

        expect(result, isA<Success<void>>());
        expect(repository.erased, 1);
        expect(reset.cleared, 1);
      },
    );

    test(
      'keeps what the app remembers when the data could not be erased',
      () async {
        repository.eraseError = StorageException(Exception('disk full'));

        final result = await EraseAllData(repository, reset)();

        expect((result as Failure).failure, isA<StorageFailure>());
        expect(reset.cleared, 0);
      },
    );
  });

  group('SharedPreferencesReset', () {
    test('forgets every saved preference', () async {
      SharedPreferences.setMockInitialValues({
        'onboarding_completed': true,
        'currency': 'USD',
        'biometric_enabled': true,
        'dismissed_alerts': ['dup:1'],
        'last_backup_at': 123,
      });
      final preferences = await SharedPreferences.getInstance();

      await SharedPreferencesReset(preferences).clear();

      expect(preferences.getKeys(), isEmpty);
    });
  });
  group('EraseDataCubit', () {
    late FakeBackupRepository repository;
    late FakeBackupHistory history;

    EraseDataCubit build() => EraseDataCubit(
      EraseAllData(repository, FakeLocalStateReset()),
      history,
    );

    setUp(() {
      repository = FakeBackupRepository();
      history = FakeBackupHistory();
    });

    test('starts with when the last backup was made', () {
      history.last = DateTime(2026, 11, 1);

      expect(build().state.lastBackupAt, DateTime(2026, 11, 1));
      expect(build().state.status, EraseStatus.idle);
    });

    test('knows when no backup was ever made', () {
      expect(build().state.lastBackupAt, isNull);
    });

    test('ends done once everything is deleted', () async {
      final cubit = build();

      await cubit.erase();

      expect(cubit.state.status, EraseStatus.done);
      expect(repository.erased, 1);
    });

    test('ends failed, and can be tried again', () async {
      repository.eraseError = StorageException(Exception('disk full'));
      final cubit = build();

      await cubit.erase();
      expect(cubit.state.status, EraseStatus.failed);

      cubit.acknowledgeFailure();
      repository.eraseError = null;
      await cubit.erase();

      expect(cubit.state.status, EraseStatus.done);
    });

    test('making a backup is remembered for the reminder', () async {
      final h = BackupHarness();
      addTearDown(h.cubit.close);

      await h.cubit.createBackup();

      expect(h.history.last, h.repository.data.createdAt);
    });
  });
}
