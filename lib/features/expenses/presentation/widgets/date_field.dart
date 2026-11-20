import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Read-only field that opens a date picker. By default it is for the date of
/// an expense, so dates in the future are not offered; pass [firstDate] and
/// [lastDate] for a field that looks ahead, such as a recurring expense.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.date,
    required this.onChanged,
    this.errorText,
    this.label = 'Date',
    this.firstDate,
    this.lastDate,
  });

  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;
  final String label;

  /// The earliest date offered. Defaults to the year 2000.
  final DateTime? firstDate;

  /// The latest date offered. Defaults to today.
  final DateTime? lastDate;

  Future<void> _pick(BuildContext context) async {
    final first = firstDate ?? DateTime(2000);
    final last = lastDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      // The picker refuses an initial date outside its range.
      initialDate: date.isBefore(first)
          ? first
          : date.isAfter(last)
          ? last
          : date,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(DateFormat.yMMMd().format(date)),
      ),
    );
  }
}
