import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
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
          body: SafeArea(
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                children: [
                  const Gap(AppSpacing.sm),
                  Row(
                    children: [
                      SizedBox(
                        width: 56,
                        child: isFirst
                            ? null
                            : IconButton(
                                tooltip: 'Back',
                                onPressed: _back,
                                icon: const Icon(Icons.arrow_back),
                              ),
                      ),
                      Expanded(
                        child: StepProgressBar(
                          count: onboardingSlides.length,
                          current: state.page,
                        ),
                      ),
                      SizedBox(
                        width: 56,
                        child: isLast
                            ? null
                            : TextButton(
                                onPressed: cubit.complete,
                                child: const Text('Skip'),
                              ),
                      ),
                    ],
                  ),
                  const Gap(AppSpacing.lg),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: onboardingSlides.length,
                      onPageChanged: cubit.pageChanged,
                      itemBuilder: (_, index) =>
                          OnboardingSlideView(slide: onboardingSlides[index]),
                    ),
                  ),
                  const Gap(AppSpacing.lg),
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
                  const Gap(AppSpacing.xl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
