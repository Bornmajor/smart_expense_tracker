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

  /// Optional short title, such as "Lunch with team". Empty when not set.
  /// Added in schema version 2.
  TextColumn get title => text().withDefault(const Constant(''))();
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

@DataClassName('BudgetRow')
class Budgets extends Table {
  /// A category id, or `*` for the overall budget. Added in schema version 3.
  /// It is not a foreign key, because `*` is not a category; deleting a
  /// category removes its budget in the same transaction instead.
  TextColumn get scopeId => text()();

  /// The monthly limit in minor units (cents).
  IntColumn get limitMinor => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {scopeId};
}
