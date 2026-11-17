import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Categories, Expenses])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// The on-device database used by the app.
  factory AppDatabase.local() =>
      AppDatabase(driftDatabase(name: 'spendwise_iq'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await batch((b) => b.insertAll(categories, _defaultCategories()));
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
