import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';

import '../features/backup/backup_fakes.dart';
import '../support/pump_app.dart';

/// Deleting everything, from Settings.
void main() {
  late FakeBackupRepository backup;
  late FakeBackupHistory history;
  late FakeLocalStateReset reset;

  setUp(() {
    backup = FakeBackupRepository();
    history = FakeBackupHistory();
    reset = FakeLocalStateReset();
  });

  Future<void> openErase(WidgetTester tester) async {
    await pumpRouterApp(
      tester,
      backupRepository: backup,
      backupHistory: history,
      localStateReset: reset,
    );
    await goToTab(tester, 'Settings');
    await tester.scrollUntilVisible(
      find.text('Delete all my data'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tapText(tester, 'Delete all my data');
  }

  FilledButton deleteButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Delete everything'),
  );

  testWidgets('explains what goes, what stays, and that it cannot be undone', (
    tester,
  ) async {
    await openErase(tester);

    expect(
      find.textContaining('deletes everything and starts the app again'),
      findsOneWidget,
    );
    expect(find.textContaining('as if you had just installed'), findsOneWidget);
    expect(find.textContaining('can\'t be undone'), findsOneWidget);
  });

  testWidgets('reminds the user to back up, and says if they never did', (
    tester,
  ) async {
    await openErase(tester);

    expect(find.text('Back up first?'), findsOneWidget);
    expect(find.textContaining('not made a backup yet'), findsOneWidget);
  });

  testWidgets('says when the last backup was made', (tester) async {
    history.last = DateTime(2026, 11, 1);

    await openErase(tester);

    expect(find.textContaining('November 1, 2026'), findsOneWidget);
  });

  testWidgets('the Back up now button opens the backup screen', (tester) async {
    await openErase(tester);

    await tapText(tester, 'Back up now');

    expect(find.text('Back up and restore'), findsWidgets);
    expect(find.text('Create backup'), findsOneWidget);
  });

  testWidgets('the button stays off until the word is typed', (tester) async {
    await openErase(tester);
    expect(deleteButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'delet');
    await tester.pump();
    expect(deleteButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'delete');
    await tester.pump();
    expect(deleteButton(tester).onPressed, isNotNull);
  });

  testWidgets('typing the word and pressing the button deletes everything', (
    tester,
  ) async {
    await openErase(tester);
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Delete everything'));
    await tester.pumpAndSettle();

    // The data is gone and everything the app remembered is forgotten. The
    // screen is left (the real app also starts again, see the restart test).
    expect(backup.erased, 1);
    expect(reset.cleared, 1);
    expect(find.text('Delete everything'), findsNothing);
  });

  testWidgets('a failure says so and deletes nothing', (tester) async {
    backup.eraseError = StorageException(Exception('disk full'));
    await openErase(tester);
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Delete everything'));
    await tester.pumpAndSettle();

    expect(backup.erased, 0);
    expect(reset.cleared, 0);
    expect(find.textContaining('data was not changed'), findsOneWidget);
  });
}
