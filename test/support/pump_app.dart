import 'package:smart_expense_tracker/features/backup/domain/repositories/backup_file_picker.dart';
import 'package:smart_expense_tracker/features/backup/domain/repositories/backup_history.dart';
import 'package:smart_expense_tracker/features/backup/domain/usecases/create_backup.dart';
import 'package:smart_expense_tracker/features/backup/domain/usecases/erase_all_data.dart';
import 'package:smart_expense_tracker/features/backup/domain/usecases/restore_backup.dart';

import '../features/backup/backup_fakes.dart';

import 'package:smart_expense_tracker/features/mpesa/domain/usecases/import_mpesa.dart';
import 'package:smart_expense_tracker/features/quick_add/domain/usecases/parse_quick_add.dart';
import 'package:smart_expense_tracker/features/quick_add/domain/usecases/quick_add.dart';
import 'package:smart_expense_tracker/features/insights/domain/repositories/alert_dismissals.dart';
import 'package:smart_expense_tracker/core/info/app_version.dart';
import 'package:smart_expense_tracker/features/currency_conversion/domain/repositories/exchange_rate_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/app/app_router.dart';
import 'package:smart_expense_tracker/core/links/app_links.dart';
import 'package:smart_expense_tracker/core/links/link_opener.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:smart_expense_tracker/features/recurring/domain/repositories/recurring_repository.dart';
import 'package:smart_expense_tracker/features/recurring/domain/usecases/generate_due_expenses.dart';
import 'package:smart_expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:smart_expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:smart_expense_tracker/features/expenses/domain/usecases/vendor_category_memory.dart';
import 'package:smart_expense_tracker/features/export/domain/usecases/export_month.dart';
import 'package:smart_expense_tracker/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:smart_expense_tracker/features/scan/domain/repositories/receipt_photo_source.dart';
import 'package:smart_expense_tracker/features/scan/domain/repositories/receipt_text_reader.dart';
import 'package:smart_expense_tracker/features/security/domain/repositories/biometric_authenticator.dart';
import 'package:smart_expense_tracker/features/security/domain/usecases/enable_biometric_lock.dart';
import 'package:smart_expense_tracker/features/security/presentation/cubit/security_cubit.dart';
import 'package:smart_expense_tracker/features/security/presentation/lock_session.dart';
import 'package:smart_expense_tracker/features/settings/presentation/cubit/settings_cubit.dart';

import 'fakes.dart';

/// Pumps the real router and pages with fake repositories.
/// Returns the lock session so tests can simulate leaving and returning.
Future<LockSession> pumpRouterApp(
  WidgetTester tester, {
  FakeOnboardingRepository? onboarding,
  FakeExpenseRepository? expenses,
  FakeBudgetRepository? budgets,
  FakeRecurringRepository? recurring,
  FakeBackupRepository? backupRepository,
  FakeBackupHistory? backupHistory,
  FakeLocalStateReset? localStateReset,
  FakeExchangeRateRepository? rates,
  FakeCategoryRepository? categories,
  FakeReceiptPhotoSource? photos,
  FakeReceiptTextReader? reader,
  FakeReportSharer? sharer,
  FakeReportWriter? pdfWriter,
  FakeReportWriter? csvWriter,
  FakeLinkOpener? links,
  AppLinks appLinks = const AppLinks(privacyPolicyUrl: ''),
  FakeSettingsRepository? settings,
  FakeSecurityRepository? security,
  FakeBiometricAuthenticator? authenticator,
  LockSession? lockSession,
  Size screenSize = const Size(800, 1600),
  EdgeInsets safePadding = EdgeInsets.zero,
}) async {
  tester.view.physicalSize = screenSize;
  // Simulates a notch and gesture bar (the device pixel ratio is 1 below).
  final insets = FakeViewPadding(
    left: safePadding.left,
    top: safePadding.top,
    right: safePadding.right,
    bottom: safePadding.bottom,
  );
  tester.view.padding = insets;
  tester.view.viewPadding = insets;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final onboardingRepo =
      onboarding ?? FakeOnboardingRepository(completed: true);
  final expenseRepo = expenses ?? FakeExpenseRepository();
  final categoryRepo = categories ?? FakeCategoryRepository();
  final recurringRepo = recurring ?? FakeRecurringRepository();
  final backupRepo = backupRepository ?? FakeBackupRepository();
  final history = backupHistory ?? FakeBackupHistory();
  final stateReset = localStateReset ?? FakeLocalStateReset();
  final dismissals = FakeAlertDismissals();
  final securityRepo = security ?? FakeSecurityRepository();
  final auth = authenticator ?? FakeBiometricAuthenticator();
  final settingsRepo = settings ?? FakeSettingsRepository();
  final session =
      lockSession ?? LockSession(enabled: securityRepo.isBiometricEnabled);

  await tester.pumpWidget(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<OnboardingRepository>.value(value: onboardingRepo),
        RepositoryProvider<ExpenseRepository>.value(value: expenseRepo),
        RepositoryProvider<VendorCategoryMemory>.value(
          value: VendorCategoryMemory(expenseRepo),
        ),
        RepositoryProvider<CategoryRepository>.value(value: categoryRepo),
        RepositoryProvider<BudgetRepository>.value(
          value: budgets ?? FakeBudgetRepository(),
        ),
        RepositoryProvider<RecurringRepository>.value(value: recurringRepo),
        RepositoryProvider<ExchangeRateRepository>.value(
          value: rates ?? FakeExchangeRateRepository(),
        ),
        RepositoryProvider<AlertDismissals>.value(value: dismissals),
        RepositoryProvider<BackupHistory>.value(value: history),
        RepositoryProvider<EraseAllData>.value(
          value: EraseAllData(backupRepo, stateReset),
        ),
        RepositoryProvider<CreateBackup>.value(
          value: CreateBackup(
            repository: backupRepo,
            codec: testCodec(),
            sharer: FakeReportSharer(),
            currencyCode: () => null,
            history: history,
          ),
        ),
        RepositoryProvider<RestoreBackup>.value(
          value: RestoreBackup(backupRepo, testCodec()),
        ),
        RepositoryProvider<BackupFilePicker>.value(
          value: FakeBackupFilePicker(),
        ),
        RepositoryProvider<ImportMpesa>.value(
          value: ImportMpesa(
            expenses: expenseRepo,
            categories: categoryRepo,
            memory: VendorCategoryMemory(expenseRepo),
          ),
        ),
        RepositoryProvider<QuickAdd>.value(
          value: QuickAdd(
            categories: categoryRepo,
            memory: VendorCategoryMemory(expenseRepo),
            parse: ParseQuickAdd(now: () => DateTime.now()),
          ),
        ),
        RepositoryProvider<AppVersion>.value(
          value: const AppVersion(name: '1.2.3', build: '45'),
        ),
        RepositoryProvider<GenerateDueExpenses>.value(
          value: GenerateDueExpenses(recurringRepo),
        ),
        RepositoryProvider<ExportMonth>.value(
          value: ExportMonth(
            expenses: expenseRepo,
            categories: categoryRepo,
            pdf: pdfWriter ?? FakeReportWriter('pdf'),
            csv: csvWriter ?? FakeReportWriter('csv'),
            sharer: sharer ?? FakeReportSharer(),
            currency: () => settingsRepo.currency,
          ),
        ),
        RepositoryProvider<AppLinks>.value(value: appLinks),
        RepositoryProvider<LinkOpener>.value(value: links ?? FakeLinkOpener()),
        RepositoryProvider<BiometricAuthenticator>.value(value: auth),
        RepositoryProvider<ReceiptPhotoSource>.value(
          value: photos ?? FakeReceiptPhotoSource(),
        ),
        RepositoryProvider<ReceiptTextReader>.value(
          value: reader ?? FakeReceiptTextReader(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => SettingsCubit(settingsRepo)),
          BlocProvider(
            create: (_) => SecurityCubit(
              securityRepo,
              EnableBiometricLock(securityRepo, auth),
              session,
            ),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: createRouter(
            onboarding: onboardingRepo,
            lockSession: session,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return session;
}

Future<void> tapText(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Taps a bottom navigation tab (the label also appears as a page title).
Future<void> goToTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}
