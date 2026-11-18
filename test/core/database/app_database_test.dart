import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/database/app_database.dart';

/// Builds the database as the first release created it (schema version 1,
/// no title column), with one category and, optionally, one expense.
AppDatabase openVersion1Database({bool withExpense = false}) => AppDatabase(
  NativeDatabase.memory(
    // `raw` is the underlying sqlite3 database.
    setup: (dynamic raw) {
      raw.execute(
        'CREATE TABLE categories (id TEXT NOT NULL, name TEXT NOT NULL, '
        'created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, '
        'PRIMARY KEY (id))',
      );
      raw.execute(
        'CREATE TABLE expenses (id TEXT NOT NULL, vendor TEXT NOT NULL, '
        'amount_minor INTEGER NOT NULL, date INTEGER NOT NULL, '
        'category_id TEXT NOT NULL REFERENCES categories (id), '
        'created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL, '
        'PRIMARY KEY (id))',
      );
      raw.execute("INSERT INTO categories VALUES ('food', 'Food', 1, 1)");
      if (withExpense) {
        raw.execute(
          "INSERT INTO expenses VALUES "
          "('old', 'Shell', 4520, 1760000000, 'food', 1, 1)",
        );
      }
      raw.execute('PRAGMA user_version = 1');
    },
  ),
);

ExpensesCompanion newExpense({String id = 'e1', Value<String>? title}) =>
    ExpensesCompanion.insert(
      id: id,
      title: title ?? const Value.absent(),
      vendor: 'Cafe',
      amountMinor: 500,
      date: DateTime(2026, 11, 16),
      categoryId: 'food',
      createdAt: DateTime(2026, 11, 16),
      updatedAt: DateTime(2026, 11, 16),
    );

void main() {
  group('AppDatabase', () {
    test('a new database starts with the default categories', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final names = (await db.select(db.categories).get()).map((c) => c.name);

      expect(
        names,
        containsAll(['Food', 'Transport', 'Bills', 'Shopping', 'Health']),
      );
    });

    test('an expense saved without a title has an empty one', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await db.into(db.expenses).insert(newExpense());

      expect((await db.select(db.expenses).getSingle()).title, isEmpty);
    });

    test(
      'upgrading from version 1 keeps every expense, with no title',
      () async {
        final db = openVersion1Database(withExpense: true);
        addTearDown(db.close);

        final rows = await db.select(db.expenses).get();

        expect(rows, hasLength(1));
        expect(rows.single.id, 'old');
        expect(rows.single.vendor, 'Shell');
        expect(rows.single.amountMinor, 4520);
        expect(rows.single.title, isEmpty);
      },
    );

    test('an upgraded database can save a titled expense', () async {
      final db = openVersion1Database();
      addTearDown(db.close);

      await db
          .into(db.expenses)
          .insert(newExpense(title: const Value('Team lunch')));

      expect((await db.select(db.expenses).getSingle()).title, 'Team lunch');
    });
  });
}
