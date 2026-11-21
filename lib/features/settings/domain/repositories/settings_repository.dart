import '../../../../core/utils/currency.dart';
import '../entities/app_theme_mode.dart';

abstract interface class SettingsRepository {
  AppThemeMode get themeMode;

  Future<void> setThemeMode(AppThemeMode mode);

  /// The currency amounts are shown in.
  Currency get currency;

  Future<void> setCurrency(Currency currency);
}
