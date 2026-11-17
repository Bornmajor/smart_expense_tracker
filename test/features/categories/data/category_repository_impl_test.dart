import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/database/app_database.dart';
import 'package:smart_expense_tracker/features/categories/data/repositories/category_repository_impl.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  group('CategoryRepositoryImpl', () {
    test('starts with the default categories, sorted by name', () async {
      final categories = await CategoryRepositoryImpl(db).watchAll().first;

      expect(categories.map((c) => c.name), [
        'Bills',
        'Food',
        'Health',
        'Other',
        'Shopping',
        'Transport',
      ]);
      expect(categories.map((c) => c.id), contains('other'));
    });
  });
}
