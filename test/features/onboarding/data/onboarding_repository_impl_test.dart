import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expense_tracker/features/onboarding/data/repositories/onboarding_repository_impl.dart';

void main() {
  Future<OnboardingRepositoryImpl> repository(
    Map<String, Object> initialValues,
  ) async {
    SharedPreferences.setMockInitialValues(initialValues);
    return OnboardingRepositoryImpl(await SharedPreferences.getInstance());
  }

  group('OnboardingRepositoryImpl', () {
    test('is not completed on a fresh install', () async {
      expect((await repository({})).isCompleted, isFalse);
    });

    test('remembers completion', () async {
      final repo = await repository({});

      await repo.complete();

      expect(repo.isCompleted, isTrue);
    });

    test('reads a previously saved completion', () async {
      final repo = await repository({'onboarding_completed': true});

      expect(repo.isCompleted, isTrue);
    });
  });
}
