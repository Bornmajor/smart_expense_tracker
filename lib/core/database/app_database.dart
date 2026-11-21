import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Categories, Expenses, Budgets, RecurringRules])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The on-device database used by the app.
  factory AppDatabase.local() =>
      AppDatabase(driftDatabase(name: 'spendwise_iq'));

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await batch((b) => b.insertAll(categories, _defaultCategories()));
    },
    onUpgrade: (migrator, from, to) async {
      // Version 2 added an optional title. Existing expenses get no title.
      if (from < 2) await migrator.addColumn(expenses, expenses.title);
      // Version 3 added budgets. Nothing to carry over: there were none.
      if (from < 3) await migrator.createTable(budgets);
      // Version 4 added recurring rules, and a marker on expenses saying which
      // rule added them. Existing expenses were all added by hand.
      if (from < 4) {
        await migrator.createTable(recurringRules);
        await migrator.addColumn(expenses, expenses.recurringRuleId);
      }
      // Version 5 added the original amount of a converted expense. Existing
      // expenses were all entered in the one currency, so both stay empty.
      if (from < 5) {
        await migrator.addColumn(expenses, expenses.originalAmountMinor);
        await migrator.addColumn(expenses, expenses.originalCurrency);
      }
      // Version 6 added the M-Pesa transaction code. Existing expenses have
      // none.
      if (from < 6) {
        await migrator.addColumn(expenses, expenses.transactionCode);
      }
    },
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );

  /// Deletes every expense, recurring rule, budget and category, then puts
  /// back the starting categories, in one step: either all of it happens or
  /// nothing does.
  Future<void> eraseAllData() => transaction(() async {
    // Children first: expenses point at categories and rules.
    await delete(expenses).go();
    await delete(recurringRules).go();
    await delete(budgets).go();
    await delete(categories).go();
    await batch((b) => b.insertAll(categories, _defaultCategories()));
  });

  List<CategoriesCompanion> _defaultCategories() {
    final now = DateTime.now();
    const names = {
      'food': 'Food',
      'transport': 'Transport',
      'bills': 'Bills',
      'shopping': 'Shopping',
      'health': 'Health',
      'other': 'Other',
    };
    return [
      for (final entry in names.entries)
        CategoriesCompanion.insert(
          id: entry.key,
          name: entry.value,
          createdAt: now,
          updatedAt: now,
        ),
    ];
  }
}
