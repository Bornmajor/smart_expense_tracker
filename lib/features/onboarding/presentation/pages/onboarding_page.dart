import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../onboarding_slides.dart';
import '../widgets/onboarding_slide_view.dart';
import '../widgets/step_progress_bar.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _slideDuration = Duration(milliseconds: 300);

  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() =>
      _controller.nextPage(duration: _slideDuration, curve: Curves.easeOut);

  void _back() =>
      _controller.previousPage(duration: _slideDuration, curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: (previous, current) =>
          !previous.completed && current.completed,
      listener: (context, _) => context.go(AppRoutes.expenses),
      builder: (context, state) {
        final isFirst = state.page == 0;
        final isLast = state.page == onboardingSlides.length - 1;
        return Scaffold(
          backgroundColor: context.scheme.surface,
          body: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: onboardingSlides.length,
                onPageChanged: cubit.pageChanged,
                itemBuilder: (_, index) =>
                    OnboardingSlideView(slide: onboardingSlides[index]),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: AppSpacing.screen.copyWith(top: AppSpacing.sm),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: isFirst
                              ? null
                              : IconButton(
                                  tooltip: 'Back',
                                  onPressed: _back,
                                  style: IconButton.styleFrom(
                                    backgroundColor: context.scheme.surface,
                                  ),
                                  icon: const Icon(Icons.chevron_left),
                                ),
                        ),
                        const Gap(AppSpacing.sm),
                        Expanded(
                          child: StepProgressBar(
                            count: onboardingSlides.length,
                            current: state.page,
                          ),
                        ),
                        const Gap(AppSpacing.sm),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: AppSpacing.screen.copyWith(bottom: AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton(
                          onPressed: isLast ? cubit.complete : _next,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(isLast ? 'Get started' : 'Next'),
                              const Gap(AppSpacing.sm),
                              const Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                        const Gap(AppSpacing.sm),
                        // Keeps its height on the last slide so nothing jumps.
                        SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: isLast
                              ? null
                              : TextButton(
                                  onPressed: cubit.complete,
                                  child: const Text('Skip'),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
