import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:smart_expense_tracker/features/onboarding/presentation/cubit/onboarding_state.dart';

import '../../../../support/fakes.dart';

void main() {
  late FakeOnboardingRepository repository;

  late FakeProfileRepository profile;

  setUp(() {
    repository = FakeOnboardingRepository();
    profile = FakeProfileRepository();
  });

  group('OnboardingCubit', () {
    blocTest<OnboardingCubit, OnboardingState>(
      'tracks the current page',
      build: () => OnboardingCubit(repository, profile),
      act: (cubit) => cubit
        ..pageChanged(1)
        ..pageChanged(2),
      expect: () => const [OnboardingState(page: 1), OnboardingState(page: 2)],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'saves completion and reports it',
      build: () => OnboardingCubit(repository, profile),
      act: (cubit) => cubit.complete(),
      expect: () => const [OnboardingState(completed: true)],
      verify: (_) => expect(repository.isCompleted, isTrue),
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'keeps the name typed on the last screen',
      build: () => OnboardingCubit(repository, profile),
      act: (cubit) => cubit.complete(name: '  Maja '),
      verify: (_) => expect(profile.stored, 'Maja'),
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'keeps no name when none was typed or the screen was skipped',
      build: () => OnboardingCubit(repository, profile),
      act: (cubit) => cubit.complete(name: '   '),
      verify: (_) => expect(profile.stored, isEmpty),
    );
  });
}
