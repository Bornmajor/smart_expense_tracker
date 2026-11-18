import 'package:intl/intl.dart';

/// "Today", "Yesterday", or a short date such as "Mon, Nov 16".
/// The year is added when the day is not in the current year.
String dayLabel(DateTime day, DateTime now) {
  final date = DateTime(day.year, day.month, day.day);
  final today = DateTime(now.year, now.month, now.day);
  final difference = today.difference(date).inDays;

  if (difference == 0) return 'Today';
  if (difference == 1) return 'Yesterday';
  return date.year == today.year
      ? DateFormat.MMMEd().format(date)
      : DateFormat.yMMMEd().format(date);
}
