import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../onboarding_slides.dart';

/// One onboarding page. The slide's color fills the whole screen, with the
/// illustration on top and the title and description below. The progress bar
/// and buttons are drawn over it by the page, so they stay put while pages
/// slide.
///
/// The text area is at least half the screen. If the text (or a large font
/// size) needs more room, it grows and the illustration shrinks, so the text
/// never runs under the buttons.
class OnboardingSlideView extends StatelessWidget {
  const OnboardingSlideView({super.key, required this.slide});

  final OnboardingSlide slide;

  /// Room kept free at the top for the back button and progress bar.
  static const topBarSpace = 72.0;

  /// Height of the Next and Skip buttons the page draws over the bottom:
  /// 16 padding + 52 button + 8 gap + 48 skip.
  static const buttonsAreaHeight = 124.0;

  @override
  Widget build(BuildContext context) {
    final buttonsSpace =
        buttonsAreaHeight + MediaQuery.paddingOf(context).bottom;

    return ColoredBox(
      color: slide.color,
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          children: [
            Expanded(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    topBarSpace,
                    AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  child: Image.asset(
                    slide.image,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight / 2),
              // Sides only: the bottom is already kept clear for the buttons.
              child: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: AppSpacing.screen.copyWith(bottom: buttonsSpace),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        slide.title,
                        textAlign: TextAlign.center,
                        style: context.text.headlineMedium?.copyWith(
                          color: onboardingInk,
                          fontSize: 32,
                          height: 1.15,
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      Text(
                        slide.description,
                        textAlign: TextAlign.center,
                        style: context.text.bodyLarge?.copyWith(
                          color: onboardingInk.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
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
