import 'package:drift/drift.dart' show Value;

import '../../../../core/database/app_database.dart';
import '../../domain/entities/expense.dart';

extension ExpenseRowMapper on ExpenseRow {
  Expense toEntity() => Expense(
    id: id,
    title: title,
    vendor: vendor,
    amountMinor: amountMinor,
    date: date,
    categoryId: categoryId,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension ExpenseEntityMapper on Expense {
  ExpensesCompanion toCompanion() => ExpensesCompanion.insert(
    id: id,
    title: Value(title),
    vendor: vendor,
    amountMinor: amountMinor,
    date: date,
    categoryId: categoryId,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
