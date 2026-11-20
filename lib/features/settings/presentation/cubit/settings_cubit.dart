import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/currency.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/repositories/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(SettingsRepository repository)
    : _repository = repository,
      super(
        SettingsState(
          themeMode: repository.themeMode,
          currency: repository.currency,
        ),
      );

  final SettingsRepository _repository;

  Future<void> setThemeMode(AppThemeMode mode) async {
    await _repository.setThemeMode(mode);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setCurrency(Currency currency) async {
    await _repository.setCurrency(currency);
    emit(state.copyWith(currency: currency));
  }
}
