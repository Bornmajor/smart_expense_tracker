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

  /// The recurring rule that added this expense, if one did. Added in schema
  /// version 4. Deleting the rule only clears this; the expense stays.
  TextColumn get recurringRuleId => text().nullable().references(
    RecurringRules,
    #id,
    onDelete: KeyAction.setNull,
  )();

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

@DataClassName('RecurringRuleRow')
class RecurringRules extends Table {
  TextColumn get id => text()();

  /// Optional short note such as "Family plan". Empty when not set. Added in
  /// schema version 4, with the rest of this table.
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get vendor => text()();

  /// What each occurrence costs, in minor units (cents).
  IntColumn get amountMinor => integer()();
  TextColumn get categoryId => text().references(Categories, #id)();

  /// The name of a `RecurrenceFrequency`: weekly, monthly or yearly.
  TextColumn get frequency => text()();

  /// The date the schedule is counted from, so month-end dates do not drift.
  DateTimeColumn get anchor => dateTime()();

  /// The next date an expense is added for.
  DateTimeColumn get nextDue => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
