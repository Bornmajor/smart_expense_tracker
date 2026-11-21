import 'package:equatable/equatable.dart';

/// What was found in a line such as "lunch 350 at Java yesterday". Any part may
/// be missing; the user checks it all in the expense form before saving.
class QuickAddDraft extends Equatable {
  const QuickAddDraft({
    this.amountMinor,
    this.date,
    this.vendor = '',
    this.title = '',
  });

  /// In minor units (cents), or null when no amount was found.
  final int? amountMinor;

  /// A plain date, or null when the line named none (the form then uses today).
  final DateTime? date;
  final String vendor;
  final String title;

  @override
  List<Object?> get props => [amountMinor, date, vendor, title];
}
