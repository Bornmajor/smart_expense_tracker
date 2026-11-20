import 'package:equatable/equatable.dart';

import '../../../../core/utils/currency.dart';
import '../../domain/entities/app_theme_mode.dart';

class SettingsState extends Equatable {
  const SettingsState({required this.themeMode, this.currency = Currency.none});

  final AppThemeMode themeMode;
  final Currency currency;

  SettingsState copyWith({AppThemeMode? themeMode, Currency? currency}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      currency: currency ?? this.currency,
    );
  }

  @override
  List<Object?> get props => [themeMode, currency];
}
