import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_theme_mode.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._preferences);

  static const _themeKey = 'theme_mode';

  final SharedPreferences _preferences;

  @override
  AppThemeMode get themeMode =>
      AppThemeMode.values.asNameMap()[_preferences.getString(_themeKey)] ??
      AppThemeMode.system;

  @override
  Future<void> setThemeMode(AppThemeMode mode) async {
    await _preferences.setString(_themeKey, mode.name);
  }
}
