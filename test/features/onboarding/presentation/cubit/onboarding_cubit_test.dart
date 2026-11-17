import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:smart_expense_tracker/features/onboarding/presentation/cubit/onboarding_state.dart';

import '../../../../support/fakes.dart';

void main() {
  late FakeOnboardingRepository repository;

  setUp(() => repository = FakeOnboardingRepository());

  group('OnboardingCubit', () {
    blocTest<OnboardingCubit, OnboardingState>(
      'tracks the current page',
      build: () => OnboardingCubit(repository),
      act: (cubit) => cubit
        ..pageChanged(1)
        ..pageChanged(2),
      expect: () => const [OnboardingState(page: 1), OnboardingState(page: 2)],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'saves completion and reports it',
      build: () => OnboardingCubit(repository),
      act: (cubit) => cubit.complete(),
      expect: () => const [OnboardingState(completed: true)],
      verify: (_) => expect(repository.isCompleted, isTrue),
    );
  });
}
