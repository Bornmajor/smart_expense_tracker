import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/theme_x.dart';

/// "‹ November 2026 ›". Pass null for [onNext] to disable the next arrow.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous month',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        // Takes the room between the arrows and shrinks to fit it, so a long month
        // name, a wide font or a large text size never overflows the row.
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                DateFormat.yMMMM().format(month),
                maxLines: 1,
                softWrap: false,
                style: context.text.titleMedium,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
