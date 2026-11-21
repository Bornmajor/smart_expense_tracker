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
    recurringRuleId: recurringRuleId,
    originalAmountMinor: originalAmountMinor,
    originalCurrency: originalCurrency,
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
    recurringRuleId: Value(recurringRuleId),
    originalAmountMinor: Value(originalAmountMinor),
    originalCurrency: Value(originalCurrency),
  );
}
