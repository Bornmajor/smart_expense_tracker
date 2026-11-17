abstract interface class OnboardingRepository {
  /// True once the user has finished (or skipped) the welcome and onboarding.
  bool get isCompleted;

  Future<void> complete();
}
