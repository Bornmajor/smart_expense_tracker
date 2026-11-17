import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expense_tracker/features/security/data/repositories/security_repository_impl.dart';
import 'package:smart_expense_tracker/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:smart_expense_tracker/features/settings/domain/entities/app_theme_mode.dart';
import 'package:smart_expense_tracker/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:smart_expense_tracker/features/settings/presentation/cubit/settings_state.dart';

import '../../support/fakes.dart';

void main() {
  Future<SharedPreferences> prefs([Map<String, Object> values = const {}]) {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  group('SettingsRepositoryImpl', () {
    test('defaults to the system theme', () async {
      expect(
        SettingsRepositoryImpl(await prefs()).themeMode,
        AppThemeMode.system,
      );
    });

    test('remembers the chosen theme', () async {
      final repo = SettingsRepositoryImpl(await prefs());

      await repo.setThemeMode(AppThemeMode.dark);

      expect(repo.themeMode, AppThemeMode.dark);
    });

    test('falls back to system for an unknown saved value', () async {
      final repo = SettingsRepositoryImpl(await prefs({'theme_mode': 'neon'}));

      expect(repo.themeMode, AppThemeMode.system);
    });
  });

  group('SecurityRepositoryImpl', () {
    test('is off by default and remembers the switch', () async {
      final repo = SecurityRepositoryImpl(await prefs());
      expect(repo.isBiometricEnabled, isFalse);

      await repo.setBiometricEnabled(true);

      expect(repo.isBiometricEnabled, isTrue);
    });
  });

  group('SettingsCubit', () {
    test('starts with the saved theme', () {
      final cubit = SettingsCubit(
        FakeSettingsRepository(mode: AppThemeMode.light),
      );

      expect(cubit.state.themeMode, AppThemeMode.light);
    });

    blocTest<SettingsCubit, SettingsState>(
      'saves and emits a new theme',
      build: () => SettingsCubit(FakeSettingsRepository()),
      act: (c) => c.setThemeMode(AppThemeMode.dark),
      expect: () => const [SettingsState(themeMode: AppThemeMode.dark)],
    );
  });
}
