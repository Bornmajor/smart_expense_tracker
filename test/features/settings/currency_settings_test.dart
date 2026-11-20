import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expense_tracker/core/utils/currency.dart';
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

  group('SettingsRepositoryImpl currency', () {
    test('starts with plain numbers when nothing else is set', () async {
      expect(SettingsRepositoryImpl(await prefs()).currency, Currency.none);
    });

    test('starts with the fallback until the user chooses', () async {
      final repo = SettingsRepositoryImpl(
        await prefs(),
        fallbackCurrency: Currency.kes,
      );

      expect(repo.currency, Currency.kes);
    });

    test('remembers the chosen currency', () async {
      final repo = SettingsRepositoryImpl(
        await prefs(),
        fallbackCurrency: Currency.kes,
      );

      await repo.setCurrency(Currency.usd);

      expect(repo.currency, Currency.usd);
    });

    test('a saved choice beats the fallback after a restart', () async {
      final first = SettingsRepositoryImpl(await prefs());
      await first.setCurrency(Currency.usd);

      final second = SettingsRepositoryImpl(
        await SharedPreferences.getInstance(),
        fallbackCurrency: Currency.kes,
      );

      expect(second.currency, Currency.usd);
    });

    test('"No symbol" is a real choice, not "nothing chosen"', () async {
      final repo = SettingsRepositoryImpl(
        await prefs(),
        fallbackCurrency: Currency.kes,
      );

      await repo.setCurrency(Currency.none);

      expect(repo.currency, Currency.none);
    });

    test('falls back for a saved code that is not offered', () async {
      final repo = SettingsRepositoryImpl(
        await prefs({'currency_code': 'XYZ'}),
        fallbackCurrency: Currency.kes,
      );

      expect(repo.currency, Currency.kes);
    });
  });

  group('SettingsCubit currency', () {
    test('starts with the saved currency', () {
      final cubit = SettingsCubit(
        FakeSettingsRepository(selectedCurrency: Currency.kes),
      );

      expect(cubit.state.currency, Currency.kes);
    });

    blocTest<SettingsCubit, SettingsState>(
      'saves and emits a new currency',
      build: () => SettingsCubit(FakeSettingsRepository()),
      act: (c) => c.setCurrency(Currency.usd),
      expect: () => const [
        SettingsState(themeMode: AppThemeMode.system, currency: Currency.usd),
      ],
      verify: (c) => expect(c.state.currency, Currency.usd),
    );

    blocTest<SettingsCubit, SettingsState>(
      'changing the theme keeps the currency',
      build: () =>
          SettingsCubit(FakeSettingsRepository(selectedCurrency: Currency.kes)),
      act: (c) => c.setThemeMode(AppThemeMode.dark),
      expect: () => const [
        SettingsState(themeMode: AppThemeMode.dark, currency: Currency.kes),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'changing the currency keeps the theme',
      build: () =>
          SettingsCubit(FakeSettingsRepository(mode: AppThemeMode.light)),
      act: (c) => c.setCurrency(Currency.kes),
      expect: () => const [
        SettingsState(themeMode: AppThemeMode.light, currency: Currency.kes),
      ],
    );

    test('the repository really gets the new currency', () async {
      final repo = FakeSettingsRepository();
      final cubit = SettingsCubit(repo);

      await cubit.setCurrency(Currency.kes);

      expect(repo.currency, Currency.kes);
    });
  });
}
