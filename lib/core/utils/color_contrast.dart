import 'dart:math' as math;
import 'dart:ui';

import '../theme/app_colors.dart';

/// WCAG contrast ratio between two colors, from 1 (identical) to 21.
/// 4.5 or more is the minimum for normal text.
double contrastRatio(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = math.max(first, second);
  final darker = math.min(first, second);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Black or white, whichever reads better on [background].
Color readableOn(Color background) {
  return contrastRatio(background, AppColors.black) >=
          contrastRatio(background, AppColors.white)
      ? AppColors.black
      : AppColors.white;
}
