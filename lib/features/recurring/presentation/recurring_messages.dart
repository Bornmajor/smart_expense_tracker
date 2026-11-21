import '../domain/validation/recurring_checks.dart';

/// Turns a recurring-rule error code into text for the user.
String recurringErrorMessage(String code) => switch (code) {
  RecurringError.nameRequired => 'Enter a name or a note',
  RecurringError.nameTooLong => 'That is too long',
  RecurringError.amountRequired => 'Enter an amount',
  RecurringError.amountInvalid => 'Enter a number, such as 1200 or 1200.50',
  RecurringError.amountMustBePositive => 'The amount must be more than zero',
  RecurringError.amountTooLarge => 'That is more than an amount can be',
  RecurringError.categoryRequired => 'Choose a category',
  RecurringError.dateTooOld =>
    'Choose a date within the last year. Older dates would add a lot of '
        'past expenses.',
  RecurringError.dateTooFar => 'Choose a date within the next five years',
  _ => 'Check this field',
};
