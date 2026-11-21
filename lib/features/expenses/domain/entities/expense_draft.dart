import 'package:equatable/equatable.dart';

/// What the user entered, before it is validated and turned into an Expense.
class ExpenseDraft extends Equatable {
  const ExpenseDraft({
    required this.vendor,
    required this.amountMinor,
    required this.date,
    required this.categoryId,
    this.title = '',
    this.originalAmountMinor,
    this.originalCurrency,
    this.transactionCode,
  });

  /// Optional. Blank means no title.
  final String title;
  final String vendor;

  /// Null when the user did not enter a usable amount.
  final int? amountMinor;
  final DateTime date;
  final String? categoryId;

  /// When [amountMinor] was converted from another currency: the amount the
  /// user typed and its ISO code. Both are null for an ordinary expense.
  final int? originalAmountMinor;
  final String? originalCurrency;

  /// The M-Pesa transaction code, when the draft came from a pasted message.
  final String? transactionCode;

  @override
  List<Object?> get props => [
    title,
    vendor,
    amountMinor,
    date,
    categoryId,
    originalAmountMinor,
    originalCurrency,
    transactionCode,
  ];
}
