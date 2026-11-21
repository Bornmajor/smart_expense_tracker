import 'package:equatable/equatable.dart';

import 'budget.dart';

/// How close spending is to a limit.
enum BudgetLevel {
  /// Well within the limit.
  onTrack,

  /// 80% or more of the limit is used, but it is not passed yet.
  near,

  /// More than the limit is spent.
  over,
}

/// One budget measured against what was spent in a month.
class BudgetProgress extends Equatable {
  const BudgetProgress({required this.budget, required this.spentMinor});

  /// At what share of the limit spending counts as "near" it.
  static const nearPercent = 80;

  final Budget budget;
  final int spentMinor;

  int get limitMinor => budget.limitMinor;

  /// What is left to spend. Negative when the limit is passed.
  int get remainingMinor => limitMinor - spentMinor;

  /// Spent divided by the limit. Above 1 when the limit is passed, so a bar
  /// should cap it.
  double get fraction => spentMinor / limitMinor;

  /// Whole numbers only, so a spend of exactly 80% is never missed by a
  /// rounding error.
  BudgetLevel get level {
    if (spentMinor > limitMinor) return BudgetLevel.over;
    if (spentMinor * 100 >= limitMinor * nearPercent) return BudgetLevel.near;
    return BudgetLevel.onTrack;
  }

  @override
  List<Object?> get props => [budget, spentMinor];
}
