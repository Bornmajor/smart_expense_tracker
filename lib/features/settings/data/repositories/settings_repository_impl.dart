import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/currency.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  /// [fallbackCurrency] is used until the user picks one, such as the currency
  /// of the country the phone is set to.
  SettingsRepositoryImpl(
    this._preferences, {
    this.fallbackCurrency = Currency.none,
  });

  static const _themeKey = 'theme_mode';
  static const _currencyKey = 'currency_code';

  final SharedPreferences _preferences;
  final Currency fallbackCurrency;

  @override
  AppThemeMode get themeMode =>
      AppThemeMode.values.asNameMap()[_preferences.getString(_themeKey)] ??
      AppThemeMode.system;

  @override
  Future<void> setThemeMode(AppThemeMode mode) async {
    await _preferences.setString(_themeKey, mode.name);
  }

  /// An unknown saved code (for example from a newer version of the app) falls
  /// back instead of failing.
  @override
  Currency get currency {
    final saved = _preferences.getString(_currencyKey);
    // "No symbol" is saved as an empty code, which is a real choice and must
    // not fall back.
    if (saved == null) return fallbackCurrency;
    return Currency.byCode(saved) ?? fallbackCurrency;
  }

  @override
  Future<void> setCurrency(Currency currency) async {
    await _preferences.setString(_currencyKey, currency.code);
  }
}
