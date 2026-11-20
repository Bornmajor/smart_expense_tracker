import '../../../core/errors/app_failure.dart';
import '../domain/entities/scan_result.dart';

/// What to tell the user when a scan did not work, and what they can do.
String scanFailureMessage(ScanProblem problem) => switch (problem) {
  ScanProblem.permissionDenied =>
    'SpendWise IQ can\'t open your photos. You can allow access in your '
        'phone\'s settings, or enter the expense by hand.',
  ScanProblem.cameraUnavailable =>
    'The camera or your photos could not be opened. Try again, or enter the '
        'expense by hand.',
  ScanProblem.unreadable =>
    'We couldn\'t read this receipt. A clearer, well-lit photo usually helps. '
        'You can also enter the expense by hand.',
};

/// The notes shown above the form after a scan: what was found, and what the
/// user should check. The first note is always there; the rest depend on what
/// the reading missed or guessed.
List<String> scanReviewNotes(ScanResult scan) {
  final draft = scan.draft;

  if (draft.isEmpty) {
    return const [
      'We couldn\'t read anything from this receipt. '
          'Fill in the details yourself.',
    ];
  }

  return [
    'Check the details below before you save.',
    if (draft.totalMinor == null)
      'We couldn\'t find the total, so enter the amount.'
    else if (draft.totalIsGuess)
      'We couldn\'t find a total line, so check the amount.',
    if (draft.date == null)
      'We couldn\'t read the date, so today\'s date is filled in.',
    if (scan.suggestedCategoryId != null)
      scan.categoryFromHistory
          ? 'We chose the category you used for this vendor before. '
                'Change it if it\'s wrong.'
          : 'We suggested a category. Change it if it\'s wrong.',
  ];
}
