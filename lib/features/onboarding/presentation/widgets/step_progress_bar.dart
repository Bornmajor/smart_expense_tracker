import 'package:flutter/material.dart';

import '../../../../core/theme/theme_x.dart';

/// Segmented progress bar: segments up to and including [current] are filled.
/// The unfilled color is translucent so it reads on any background tint.
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.count,
    required this.current,
  });

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final filled = context.scheme.primary;
    final empty = context.scheme.onSurface.withValues(alpha: 0.15);
    return Semantics(
      label: 'Step ${current + 1} of $count',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < count; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= current ? filled : empty,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
