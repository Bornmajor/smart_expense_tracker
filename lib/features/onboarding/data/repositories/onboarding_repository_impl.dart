import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl(this._preferences);

  static const _key = 'onboarding_completed';

  final SharedPreferences _preferences;

  @override
  bool get isCompleted => _preferences.getBool(_key) ?? false;

  @override
  Future<void> complete() async {
    await _preferences.setBool(_key, true);
  }
}
