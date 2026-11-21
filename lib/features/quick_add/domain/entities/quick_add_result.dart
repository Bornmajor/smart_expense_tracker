import 'package:equatable/equatable.dart';

import 'quick_add_draft.dart';

/// A typed line, understood and ready to fill in the expense form.
class QuickAddResult extends Equatable {
  const QuickAddResult({
    required this.text,
    required this.draft,
    this.suggestedCategoryId,
    this.categoryFromHistory = false,
  });

  /// What the user typed, shown above the form so they can compare.
  final String text;
  final QuickAddDraft draft;

  /// A category the line seems to belong to, or null when unclear.
  final String? suggestedCategoryId;

  /// True when the category was taken from the user's earlier expenses at this
  /// vendor, not guessed from words.
  final bool categoryFromHistory;

  @override
  List<Object?> get props => [
    text,
    draft,
    suggestedCategoryId,
    categoryFromHistory,
  ];
}
