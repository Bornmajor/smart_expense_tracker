import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';

Expense buildExpense({
  String id = 'e1',
  String vendor = 'Corner Cafe',
  int amountMinor = 500,
  DateTime? date,
  String categoryId = 'food',
}) {
  final day = date ?? DateTime(2026, 11, 16);
  return Expense(
    id: id,
    vendor: vendor,
    amountMinor: amountMinor,
    date: day,
    categoryId: categoryId,
    createdAt: day,
    updatedAt: day,
  );
}
