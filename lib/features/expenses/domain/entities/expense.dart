import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  const Expense({
    required this.id,
    required this.vendor,
    required this.amountMinor,
    required this.date,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    this.title = '',
    this.recurringRuleId,
    this.originalAmountMinor,
    this.originalCurrency,
    this.transactionCode,
  });

  final String id;

  /// Optional short title such as "Lunch with team". Empty when not set.
  final String title;
  final String vendor;

  /// Amount in minor units (cents).
  final int amountMinor;
  final DateTime date;
  final String categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The recurring rule that added this expense, or null when the user added
  /// it. It is kept when the expense is edited.
  final String? recurringRuleId;

  /// When the amount was converted from another currency: what was paid, in
  /// minor units, and its ISO code. Both are null for an ordinary expense.
  final int? originalAmountMinor;
  final String? originalCurrency;

  /// The M-Pesa transaction code when the expense came from a pasted
  /// message, or null. Used to spot the same message pasted twice.
  final String? transactionCode;

  @override
  List<Object?> get props => [
    id,
    title,
    vendor,
    amountMinor,
    date,
    categoryId,
    createdAt,
    updatedAt,
    recurringRuleId,
    originalAmountMinor,
    originalCurrency,
    transactionCode,
  ];
}
