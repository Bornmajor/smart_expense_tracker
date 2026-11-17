import 'package:drift/drift.dart';

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ExpenseRow')
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get vendor => text()();

  /// Integer minor units (cents).
  IntColumn get amountMinor => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get categoryId => text().references(Categories, #id)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
