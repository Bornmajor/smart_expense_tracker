/// How often a recurring expense repeats.
enum RecurrenceFrequency {
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  const RecurrenceFrequency(this.label);

  final String label;
}
