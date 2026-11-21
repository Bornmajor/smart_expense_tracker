import 'package:equatable/equatable.dart';

/// How this month is going against the same stretch of last month: spending up
/// to today's date, and up to the same date last month.
class MonthComparison extends Equatable {
  const MonthComparison({
    required this.currentMinor,
    required this.previousMinor,
    this.biggestChangeCategoryId,
    this.biggestChangeMinor = 0,
  });

  /// Spent this month so far.
  final int currentMinor;

  /// Spent at this point last month.
  final int previousMinor;

  /// The category whose spending changed most, or null when no category
  /// changed enough to be worth naming.
  final String? biggestChangeCategoryId;

  /// How much it changed: positive when it went up, negative when down.
  final int biggestChangeMinor;

  /// This month minus last month. Positive when spending is higher.
  int get deltaMinor => currentMinor - previousMinor;

  /// The change as a whole percent of last month, rounded. Null when there was
  /// nothing last month to compare with.
  int? get percent =>
      previousMinor == 0 ? null : (deltaMinor * 100 / previousMinor).round();

  /// True when spending is within 2% of last month, which reads as "the same".
  bool get aboutTheSame => percent != null && percent!.abs() < 2;

  @override
  List<Object?> get props => [
    currentMinor,
    previousMinor,
    biggestChangeCategoryId,
    biggestChangeMinor,
  ];
}
