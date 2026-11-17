import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Read-only field that opens a date picker. Dates in the future are not offered.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.date,
    required this.onChanged,
    this.errorText,
  });

  final DateTime date;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
          labelText: 'Date',
          errorText: errorText,
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(DateFormat.yMMMd().format(date)),
      ),
    );
  }
}
