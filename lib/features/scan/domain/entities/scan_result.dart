import 'package:equatable/equatable.dart';

import 'receipt_draft.dart';

/// A scanned receipt, ready to fill in the expense form.
class ScanResult extends Equatable {
  const ScanResult({
    required this.photoPath,
    required this.draft,
    this.suggestedCategoryId,
    this.categoryFromHistory = false,
  });

  /// A temporary copy of the photo, shown beside the form so the user can
  /// compare. It is deleted when the form closes.
  final String photoPath;

  final ReceiptDraft draft;

  /// A category the receipt seems to belong to, or null when unclear.
  final String? suggestedCategoryId;

  /// True when the category was taken from the user's earlier expenses at this
  /// vendor, not guessed from words on the receipt.
  final bool categoryFromHistory;

  @override
  List<Object?> get props => [
    photoPath,
    draft,
    suggestedCategoryId,
    categoryFromHistory,
  ];
}
