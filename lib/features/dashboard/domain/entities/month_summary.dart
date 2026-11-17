import 'package:equatable/equatable.dart';

class CategoryTotal extends Equatable {
  const CategoryTotal({
    required this.categoryId,
    required this.totalMinor,
    required this.share,
  });

  final String categoryId;
  final int totalMinor;

  /// Fraction of the month's total, from 0 to 1.
  final double share;

  @override
  List<Object?> get props => [categoryId, totalMinor, share];
}

class MonthSummary extends Equatable {
  const MonthSummary({
    required this.totalMinor,
    required this.count,
    required this.categories,
  });

  final int totalMinor;
  final int count;

  /// Largest spending category first.
  final List<CategoryTotal> categories;

  @override
  List<Object?> get props => [totalMinor, count, categories];
}
