import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';

/// "Good morning, Maja" with today's date. Without a name it is just "Good
/// morning".
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key, required this.name, required this.now});

  /// The first name, or empty when none was given.
  final String name;
  final DateTime now;

  /// The greeting for the time of day, with the name when there is one.
  static String greeting(DateTime now, String name) {
    final part = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return name.isEmpty ? part : '$part, $name';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(greeting(now, name), style: context.text.headlineMedium),
        ),
        const Gap(AppSpacing.xs),
        Text(
          DateFormat('EEEE, d MMMM').format(now),
          style: context.text.bodyMedium,
        ),
      ],
    );
  }
}
