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
  });

  final String id;
  final String vendor;

  /// Amount in minor units (cents).
  final int amountMinor;
  final DateTime date;
  final String categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    vendor,
    amountMinor,
    date,
    categoryId,
    createdAt,
    updatedAt,
  ];
}
