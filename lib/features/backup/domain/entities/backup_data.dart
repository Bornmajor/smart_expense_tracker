import 'package:equatable/equatable.dart';

/// Everything the app keeps, as it goes into a backup file.
///
/// The rows are kept as plain JSON maps, exactly as the database holds them,
/// so nothing is lost (such as the dates an expense was created and changed)
/// and a new column only needs the database layer to change.
class BackupData extends Equatable {
  const BackupData({
    required this.version,
    required this.createdAt,
    required this.categories,
    required this.expenses,
    required this.budgets,
    required this.recurringRules,
    this.currencyCode,
  });

  /// The newest file layout this version of the app understands.
  static const currentVersion = 1;

  /// The layout of the file this was read from, or [currentVersion].
  final int version;
  final DateTime createdAt;

  /// The currency shown on screen (such as "KES"), or null for plain numbers.
  final String? currencyCode;

  final List<Map<String, Object?>> categories;
  final List<Map<String, Object?>> expenses;
  final List<Map<String, Object?>> budgets;
  final List<Map<String, Object?>> recurringRules;

  @override
  List<Object?> get props => [
    version,
    createdAt,
    currencyCode,
    categories,
    expenses,
    budgets,
    recurringRules,
  ];
}
