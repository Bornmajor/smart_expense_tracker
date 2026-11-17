import 'package:flutter/material.dart';

import '../../../../core/theme/theme_x.dart';
import '../../../../shared/widgets/app_logo.dart';

/// Top part of the welcome screen: the logo surrounded by line icons.
class WelcomeHero extends StatelessWidget {
  const WelcomeHero({super.key});

  static const _decorations = [
    (Alignment(-0.78, -0.62), Icons.receipt_long_outlined),
    (Alignment(0.74, -0.72), Icons.photo_camera_outlined),
    (Alignment(-0.9, 0.08), Icons.pie_chart_outline),
    (Alignment(0.88, 0.14), Icons.fingerprint),
    (Alignment(-0.5, 0.78), Icons.savings_outlined),
    (Alignment(0.56, 0.82), Icons.ios_share_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final iconColor = context.scheme.onSurfaceVariant.withValues(alpha: 0.7);
    return ColoredBox(
      color: context.scheme.surfaceContainerHighest,
      child: Stack(
        children: [
          for (final (alignment, icon) in _decorations)
            Align(
              alignment: alignment,
              child: ExcludeSemantics(
                child: Icon(icon, size: 30, color: iconColor),
              ),
            ),
          const Center(child: AppLogo(size: 112)),
        ],
      ),
    );
  }
}
