import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/security_repository.dart';

class SecurityRepositoryImpl implements SecurityRepository {
  SecurityRepositoryImpl(this._preferences);

  static const _key = 'biometric_lock_enabled';

  final SharedPreferences _preferences;

  @override
  bool get isBiometricEnabled => _preferences.getBool(_key) ?? false;

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    await _preferences.setBool(_key, enabled);
  }
}
