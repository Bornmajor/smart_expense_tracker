import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/core/utils/currency.dart';
import 'package:smart_expense_tracker/features/backup/presentation/backup_messages.dart';
import 'package:smart_expense_tracker/features/backup/presentation/cubit/backup_cubit.dart';
import 'package:smart_expense_tracker/features/backup/presentation/cubit/backup_state.dart';
import 'package:smart_expense_tracker/features/backup/presentation/pages/backup_page.dart';
import 'package:smart_expense_tracker/features/settings/presentation/cubit/settings_cubit.dart';

import '../../support/fakes.dart';
import 'backup_fakes.dart';

void main() {
  late BackupHarness h;
  late SettingsCubit settings;

  Future<void> openPage(WidgetTester tester) async {
    settings = SettingsCubit(
      FakeSettingsRepository(selectedCurrency: Currency.kes),
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<BackupCubit>.value(value: h.cubit),
          BlocProvider<SettingsCubit>.value(value: settings),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const BackupPage()),
      ),
    );
  }

  /// Real time, for the steps (such as locking with a password) that run off
  /// the main thread. Gives up after a few seconds so a bug cannot hang.
  Future<void> waitUntil(bool Function() done) async {
    for (var i = 0; i < 250 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  bool pickFinished() => h.picker.picks > 0 && h.cubit.state is! BackupWorking;

  setUp(() => h = BackupHarness());

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('a restore shows what is in the file, then replaces the data', (
    tester,
  ) async {
    await tester.runAsync(() async {
      h.picker.bytes = await h.codec.encode(
        sampleDataWithCurrency(sampleData(), 'USD'),
      );
    });
    await openPage(tester);

    await tester.runAsync(() async {
      await tester.tap(find.text('Choose a backup file'));
      await waitUntil(pickFinished);
    });
    await tester.pumpAndSettle();

    expect(find.text('Replace your data?'), findsOneWidget);
    expect(find.textContaining('2 expenses'), findsOneWidget);
    expect(h.repository.replaced, isNull);

    await tap(tester, 'Replace');

    expect(find.text('Backup restored'), findsOneWidget);
    expect(h.repository.replaced, isNotNull);
    expect(settings.state.currency, Currency.byCode('USD'));
  });

  testWidgets('cancelling the question changes nothing', (tester) async {
    await tester.runAsync(() async {
      h.picker.bytes = await h.codec.encode(sampleData());
    });
    await openPage(tester);
    await tester.runAsync(() async {
      await tester.tap(find.text('Choose a backup file'));
      await waitUntil(pickFinished);
    });
    await tester.pumpAndSettle();

    await tap(tester, 'Cancel');

    expect(find.text('Replace your data?'), findsNothing);
    expect(h.repository.replaced, isNull);
  });

  testWidgets('a file that is not a backup is explained', (tester) async {
    h.picker.bytes = null;
    await tester.runAsync(() async {
      h.picker.bytes = (await h.codec.encode(sampleData())).sublist(0, 5);
    });
    await openPage(tester);

    await tester.runAsync(() async {
      await tester.tap(find.text('Choose a backup file'));
      await waitUntil(pickFinished);
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('not a SpendWise IQ backup'), findsOneWidget);
    expect(h.repository.replaced, isNull);
  });

  testWidgets('a password that does not match is not accepted', (tester) async {
    await openPage(tester);

    await tap(tester, 'Protect with a password');
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'secret1',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm password'),
      'secret2',
    );
    await tap(tester, 'Create backup');

    expect(find.text('The two passwords do not match.'), findsOneWidget);
    expect(h.sharer.shared, isEmpty);
  });

  testWidgets('a matching password makes a locked backup', (tester) async {
    await openPage(tester);

    await tap(tester, 'Protect with a password');
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'secret1',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Confirm password'),
      'secret1',
    );
    await tester.runAsync(() async {
      await tester.tap(find.text('Create backup'));
      await waitUntil(() => h.sharer.shared.isNotEmpty);
    });
    await tester.pumpAndSettle();

    expect(h.sharer.shared, hasLength(1));
    expect(h.codec.isEncrypted(h.sharer.shared.single.bytes), isTrue);
    expect(find.textContaining('Backup created'), findsOneWidget);
  });

  group('BackupPasswordRules', () {
    test('wants a few characters', () {
      expect(BackupPasswordRules.problem('abc', 'abc'), isNotNull);
    });

    test('wants both to match', () {
      expect(BackupPasswordRules.problem('secret1', 'secret2'), isNotNull);
    });

    test('accepts a good matching password', () {
      expect(BackupPasswordRules.problem('secret1', 'secret1'), isNull);
    });
  });
}
