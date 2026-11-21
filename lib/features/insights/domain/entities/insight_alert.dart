import 'package:equatable/equatable.dart';

enum AlertKind {
  /// Two charges of the same amount at the same vendor, a day apart or less.
  possibleDuplicate,

  /// An expense far larger than the usual ones in its category.
  unusuallyLarge,

  /// A category already above what a whole month usually costs.
  categoryAboveNormal,
}

/// Something worth a second look, found in the user's own expenses. The
/// numbers are kept here and the words are written by the screen.
class InsightAlert extends Equatable {
  const InsightAlert({
    required this.id,
    required this.kind,
    required this.categoryId,
    required this.amountMinor,
    this.vendor = '',
    this.usualMinor,
  });

  /// Stays the same for the same finding, so a dismissed alert does not come
  /// back the next time the app opens.
  final String id;
  final AlertKind kind;
  final String categoryId;

  /// The charge, or the category's total so far this month.
  final int amountMinor;
  final String vendor;

  /// What is usual for comparison: the typical expense in the category, or its
  /// average month. Null for a duplicate.
  final int? usualMinor;

  @override
  List<Object?> get props => [
    id,
    kind,
    categoryId,
    amountMinor,
    vendor,
    usualMinor,
  ];
}
