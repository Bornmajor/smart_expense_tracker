import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../profile/data/repositories/profile_repository_impl.dart';
import '../onboarding_slides.dart';
import 'onboarding_slide_view.dart';

/// The last introduction screen: a small form asking for a first name, with the
/// reason for asking. It is optional, so nothing here is required. It has an
/// icon in place of the big illustrations of the other screens, and it scrolls,
/// so the field stays visible above the keyboard on a short phone.
class OnboardingNameView extends StatelessWidget {
  const OnboardingNameView({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final buttonsSpace =
        OnboardingSlideView.buttonsAreaHeight +
        MediaQuery.paddingOf(context).bottom;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: onboardingInk.withValues(alpha: 0.35)),
    );

    return ColoredBox(
      color: nameScreenColor,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: AppSpacing.screen.copyWith(
            top: OnboardingSlideView.topBarSpace,
            bottom: buttonsSpace,
          ),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: OnboardingSlideView.maxTextScale,
            child: Column(
              children: [
                // A little graphic, not a full illustration.
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 44,
                    color: onboardingInk,
                  ),
                ),
                const Gap(AppSpacing.xl),
                Text(
                  'What should we call you?',
                  textAlign: TextAlign.center,
                  style: context.text.headlineMedium?.copyWith(
                    color: onboardingInk,
                    fontSize: 30,
                    height: 1.15,
                  ),
                ),
                const Gap(AppSpacing.md),
                // Why the name is asked for, in plain words.
                Text(
                  'Your name shows at the top of your Home screen, so the app '
                  'feels like yours. It is optional, it stays on your phone, '
                  'and it is never sent anywhere. You can change it later in '
                  'Settings.',
                  textAlign: TextAlign.center,
                  style: context.text.bodyLarge?.copyWith(
                    color: onboardingInk.withValues(alpha: 0.85),
                  ),
                ),
                const Gap(AppSpacing.xl),
                // The slides have bright backgrounds in light and dark mode
                // alike, so the field is drawn in black on a soft white,
                // whatever the theme.
                TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  maxLength: ProfileRepositoryImpl.maxLength,
                  autocorrect: false,
                  style: const TextStyle(color: onboardingInk),
                  cursorColor: onboardingInk,
                  decoration: InputDecoration(
                    hintText: 'Your first name',
                    hintStyle: TextStyle(
                      color: onboardingInk.withValues(alpha: 0.6),
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.6),
                    enabledBorder: border,
                    border: border,
                    focusedBorder: border.copyWith(
                      borderSide: const BorderSide(
                        color: onboardingInk,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
