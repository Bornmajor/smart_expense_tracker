import 'package:equatable/equatable.dart';

import 'recurrence_frequency.dart';

/// An expense that repeats, such as rent or a subscription. When a date comes
/// due, the app adds a real expense for it, which the user can edit or delete
/// like any other.
class RecurringRule extends Equatable {
  const RecurringRule({
    required this.id,
    required this.vendor,
    required this.amountMinor,
    required this.categoryId,
    required this.frequency,
    required this.anchor,
    required this.nextDue,
    required this.createdAt,
    required this.updatedAt,
    this.title = '',
    this.isActive = true,
  });

  final String id;

  /// Optional short note such as "Family plan". Empty when not set.
  final String title;
  final String vendor;

  /// What each occurrence costs, in minor units (cents).
  final int amountMinor;
  final String categoryId;
  final RecurrenceFrequency frequency;

  /// The date the schedule is counted from (a date, without a time). A monthly
  /// rule that starts on the 31st stays on the 31st, falling back to the last
  /// day of shorter months, and does not drift to the 28th for good.
  final DateTime anchor;

  /// The next date an expense is added for (a date, without a time).
  final DateTime nextDue;

  /// Paused rules add nothing, and pick up again from their next date.
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// What the rule is called on screen: its note when it has one, else the
  /// vendor.
  String get displayName => title.isNotEmpty ? title : vendor;

  /// About what this costs in a month, so rules that repeat at different
  /// speeds can be added up. A week is counted as 52/12 of a week a month.
  int get monthlyCostMinor => switch (frequency) {
    RecurrenceFrequency.weekly => (amountMinor * 52 / 12).round(),
    RecurrenceFrequency.monthly => amountMinor,
    RecurrenceFrequency.yearly => (amountMinor / 12).round(),
  };

  RecurringRule copyWith({
    DateTime? nextDue,
    DateTime? updatedAt,
    bool? isActive,
  }) => RecurringRule(
    id: id,
    title: title,
    vendor: vendor,
    amountMinor: amountMinor,
    categoryId: categoryId,
    frequency: frequency,
    anchor: anchor,
    nextDue: nextDue ?? this.nextDue,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    vendor,
    amountMinor,
    categoryId,
    frequency,
    anchor,
    nextDue,
    isActive,
    createdAt,
    updatedAt,
  ];
}
