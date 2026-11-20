import 'package:equatable/equatable.dart';

import 'recurrence_frequency.dart';

/// What the user typed for a recurring rule, before it is checked. Anything
/// may be missing or wrong; `SaveRecurringRule` checks it.
class RecurringDraft extends Equatable {
  const RecurringDraft({
    required this.vendor,
    required this.amountMinor,
    required this.categoryId,
    required this.frequency,
    required this.nextDue,
    this.title = '',
    this.isActive = true,
  });

  final String title;
  final String vendor;

  /// Null when the amount text could not be read as a number.
  final int? amountMinor;
  final String? categoryId;
  final RecurrenceFrequency frequency;

  /// The next date an expense is added for.
  final DateTime nextDue;
  final bool isActive;

  @override
  List<Object?> get props => [
    title,
    vendor,
    amountMinor,
    categoryId,
    frequency,
    nextDue,
    isActive,
  ];
}
