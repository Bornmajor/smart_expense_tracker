import 'package:equatable/equatable.dart';

import '../../domain/entities/app_theme_mode.dart';

class SettingsState extends Equatable {
  const SettingsState({required this.themeMode});

  final AppThemeMode themeMode;

  @override
  List<Object?> get props => [themeMode];
}
