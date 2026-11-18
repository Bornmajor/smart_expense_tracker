import 'package:equatable/equatable.dart';

/// What the user entered, before it is validated and turned into an Expense.
class ExpenseDraft extends Equatable {
  const ExpenseDraft({
    required this.vendor,
    required this.amountMinor,
    required this.date,
    required this.categoryId,
    this.title = '',
  });

  /// Optional. Blank means no title.
  final String title;
  final String vendor;

  /// Null when the user did not enter a usable amount.
  final int? amountMinor;
  final DateTime date;
  final String? categoryId;

  @override
  List<Object?> get props => [title, vendor, amountMinor, date, categoryId];
}
