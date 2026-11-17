import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../onboarding_slides.dart';

class OnboardingSlideView extends StatelessWidget {
  const OnboardingSlideView({super.key, required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Image.asset(
            slide.image,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        const Gap(AppSpacing.lg),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: context.text.headlineMedium,
        ),
        const Gap(AppSpacing.md),
        Text(
          slide.description,
          textAlign: TextAlign.center,
          style: context.text.bodyMedium,
        ),
      ],
    );
  }
}
