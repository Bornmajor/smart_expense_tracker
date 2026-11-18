import 'package:equatable/equatable.dart';

import 'receipt_draft.dart';

/// A scanned receipt, ready to fill in the expense form.
class ScanResult extends Equatable {
  const ScanResult({
    required this.photoPath,
    required this.draft,
    this.suggestedCategoryId,
  });

  /// A temporary copy of the photo, shown beside the form so the user can
  /// compare. It is deleted when the form closes.
  final String photoPath;

  final ReceiptDraft draft;

  /// A category the receipt seems to belong to, or null when unclear.
  final String? suggestedCategoryId;

  @override
  List<Object?> get props => [photoPath, draft, suggestedCategoryId];
}
