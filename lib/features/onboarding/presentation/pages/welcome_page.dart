import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../widgets/welcome_hero.dart';

/// First screen on a fresh install. One action, no sign-up.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scheme.surface,
      body: Column(
        children: [
          const Expanded(flex: 6, child: WelcomeHero()),
          Expanded(
            flex: 4,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: AppSpacing.screen,
                child: Column(
                  children: [
                    const Gap(AppSpacing.xl),
                    Text(
                      'Welcome to SpendWise IQ',
                      textAlign: TextAlign.center,
                      style: context.text.headlineMedium,
                    ),
                    const Gap(AppSpacing.md),
                    Text(
                      'Scan receipts, track spending, and keep everything '
                      'private on your phone.',
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium,
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => context.go(AppRoutes.onboarding),
                      child: const Text('Get started'),
                    ),
                    const Gap(AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
