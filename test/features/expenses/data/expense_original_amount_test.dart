import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/database/app_database.dart';
import 'package:smart_expense_tracker/features/expenses/data/repositories/expense_repository_impl.dart';

import '../../../support/builders.dart';

void main() {
  late AppDatabase db;
  late ExpenseRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ExpenseRepositoryImpl(db);
  });

  tearDown(() => db.close());

  test('keeps what was paid in another currency', () async {
    await repository.save(
      buildExpense(
        categoryId: 'shopping',
        amountMinor: 1290000,
        originalAmountMinor: 10000,
        originalCurrency: 'USD',
      ),
    );

    final saved = (await repository.watchAll().first).single;
    expect(saved.originalAmountMinor, 10000);
    expect(saved.originalCurrency, 'USD');
  });

  test('an ordinary expense has no original amount', () async {
    await repository.save(buildExpense(categoryId: 'food'));

    final saved = (await repository.watchAll().first).single;
    expect(saved.originalAmountMinor, isNull);
    expect(saved.originalCurrency, isNull);
  });
}
