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
  int get schemaVersion => 4;

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
    },
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );

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
