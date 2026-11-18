import 'package:equatable/equatable.dart';

/// What could be read from a receipt. Every part is optional, because OCR on
/// a crumpled photo often misses something. The user checks and fixes the
/// result in the expense form before anything is saved.
class ReceiptDraft extends Equatable {
  const ReceiptDraft({
    this.vendor,
    this.date,
    this.totalMinor,
    this.totalIsGuess = false,
  });

  final String? vendor;
  final DateTime? date;

  /// The total in minor units (cents).
  final int? totalMinor;

  /// True when no line was labelled as the total, so the total is the largest
  /// amount on the receipt. The form can ask the user to check it.
  final bool totalIsGuess;

  /// Nothing at all was found.
  bool get isEmpty => vendor == null && date == null && totalMinor == null;

  @override
  List<Object?> get props => [vendor, date, totalMinor, totalIsGuess];
}
