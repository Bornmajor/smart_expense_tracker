import 'package:equatable/equatable.dart';

/// A monthly spending limit: for one category, or for everything together.
///
/// The same limit applies to every month. There is no history of old limits,
/// so a past month is measured against the limit as it is today.
class Budget extends Equatable {
  const Budget({required this.scopeId, required this.limitMinor});

  /// Stands for the overall budget. It is not a category id, so it can never
  /// clash with one.
  static const overallId = '*';

  /// [overallId], or the id of the category this limit is for.
  final String scopeId;

  /// The limit in minor units (cents). Always more than zero.
  final int limitMinor;

  bool get isOverall => scopeId == overallId;

  @override
  List<Object?> get props => [scopeId, limitMinor];
}
