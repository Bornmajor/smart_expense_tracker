import 'package:equatable/equatable.dart';

/// What can still be spent this month without passing the overall budget,
/// once the bills that are still to come are set aside.
class SafeToSpend extends Equatable {
  const SafeToSpend({
    required this.limitMinor,
    required this.spentMinor,
    required this.upcomingMinor,
    required this.daysLeft,
  });

  /// The overall budget for the month.
  final int limitMinor;

  /// Spent so far this month. Recurring bills already added are part of it.
  final int spentMinor;

  /// Recurring bills that come due before the month ends and are not added yet.
  final int upcomingMinor;

  /// Days left in the month, today included. Always at least 1.
  final int daysLeft;

  /// What is left after spending so far and the bills still to come. Negative
  /// when they already add up to more than the budget.
  int get remainingMinor => limitMinor - spentMinor - upcomingMinor;

  /// True when the budget is already spoken for.
  bool get isOver => remainingMinor < 0;

  /// What can be spent each remaining day, rounded down. Zero when [isOver].
  int get perDayMinor => isOver ? 0 : remainingMinor ~/ daysLeft;

  @override
  List<Object?> get props => [limitMinor, spentMinor, upcomingMinor, daysLeft];
}
