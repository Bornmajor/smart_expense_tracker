import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/database/app_database.dart';
import '../core/theme/app_theme.dart';
import '../features/categories/data/repositories/category_repository_impl.dart';
import '../features/categories/domain/repositories/category_repository.dart';
import '../features/expenses/data/repositories/expense_repository_impl.dart';
import '../features/expenses/domain/repositories/expense_repository.dart';
import '../features/export/data/repositories/share_plus_report_sharer.dart';
import '../features/export/data/writers/bundled_fonts.dart';
import '../features/export/data/writers/csv_report_writer.dart';
import '../features/export/data/writers/pdf_report_writer.dart';
import '../features/export/domain/usecases/export_month.dart';
import '../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../features/scan/data/repositories/image_picker_photo_source.dart';
import '../features/scan/data/repositories/ml_kit_receipt_text_reader.dart';
import '../features/scan/domain/repositories/receipt_photo_source.dart';
import '../features/scan/domain/repositories/receipt_text_reader.dart';
import '../features/security/data/repositories/local_auth_biometric_authenticator.dart';
import '../features/security/data/repositories/security_repository_impl.dart';
import '../features/security/domain/repositories/biometric_authenticator.dart';
import '../features/security/domain/repositories/security_repository.dart';
import '../features/security/domain/usecases/enable_biometric_lock.dart';
import '../features/security/presentation/cubit/security_cubit.dart';
import '../features/security/presentation/lock_session.dart';
import '../features/settings/data/repositories/settings_repository_impl.dart';
import '../features/settings/domain/entities/app_theme_mode.dart';
import '../features/settings/domain/repositories/settings_repository.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';
import '../features/settings/presentation/cubit/settings_state.dart';
import 'app_router.dart';

class SpendWiseApp extends StatefulWidget {
  const SpendWiseApp({
    super.key,
    required this.database,
    required this.preferences,
    this.biometricAuthenticator,
  });

  final AppDatabase database;
  final SharedPreferences preferences;

  /// Replaced in tests; defaults to the real device check.
  final BiometricAuthenticator? biometricAuthenticator;

  @override
  State<SpendWiseApp> createState() => _SpendWiseAppState();
}

class _SpendWiseAppState extends State<SpendWiseApp> {
  late final OnboardingRepository _onboarding = OnboardingRepositoryImpl(
    widget.preferences,
  );
  late final SettingsRepository _settings = SettingsRepositoryImpl(
    widget.preferences,
  );
  late final SecurityRepository _security = SecurityRepositoryImpl(
    widget.preferences,
  );
  late final BiometricAuthenticator _authenticator =
      widget.biometricAuthenticator ?? LocalAuthBiometricAuthenticator();

  // Starts locked when the user turned the biometric lock on.
  late final LockSession _lockSession = LockSession(
    enabled: _security.isBiometricEnabled,
  );
  late final GoRouter _router = createRouter(
    onboarding: _onboarding,
    lockSession: _lockSession,
  );
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: _lockSession.didEnterBackground,
      onShow: _lockSession.didReturnToForeground,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _lockSession.dispose();
    super.dispose();
  }

  ThemeMode _themeMode(AppThemeMode mode) => switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OnboardingRepository>.value(value: _onboarding),
        RepositoryProvider<BiometricAuthenticator>.value(value: _authenticator),
        RepositoryProvider<ExpenseRepository>(
          create: (_) => ExpenseRepositoryImpl(widget.database),
        ),
        RepositoryProvider<CategoryRepository>(
          create: (_) => CategoryRepositoryImpl(widget.database),
        ),
        // Monthly report export. The fonts are read when a PDF is made.
        RepositoryProvider<ExportMonth>(
          create: (context) => ExportMonth(
            expenses: context.read<ExpenseRepository>(),
            categories: context.read<CategoryRepository>(),
            pdf: PdfReportWriter(loadFonts: loadBundledFonts),
            csv: const CsvReportWriter(),
            sharer: const SharePlusReportSharer(),
          ),
        ),
        // Receipt scanning. Created only when a scan starts.
        RepositoryProvider<ReceiptPhotoSource>(
          create: (_) => ImagePickerPhotoSource(ImagePicker()),
        ),
        RepositoryProvider<ReceiptTextReader>(
          create: (_) => MlKitReceiptTextReader(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SettingsCubit(_settings)),
          BlocProvider(
            create: (_) => SecurityCubit(
              _security,
              EnableBiometricLock(_security, _authenticator),
              _lockSession,
            ),
          ),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          buildWhen: (previous, current) =>
              previous.themeMode != current.themeMode,
          builder: (context, state) => MaterialApp.router(
            title: 'SpendWise IQ',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _themeMode(state.themeMode),
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
