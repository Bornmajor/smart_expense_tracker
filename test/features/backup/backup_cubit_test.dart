import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/backup/domain/backup_exception.dart';
import 'package:smart_expense_tracker/features/backup/presentation/cubit/backup_state.dart';
import 'package:smart_expense_tracker/features/export/domain/export_exception.dart';

import 'backup_fakes.dart';

void main() {
  late BackupHarness h;

  setUp(() => h = BackupHarness());
  tearDown(() => h.cubit.close());

  group('creating a backup', () {
    test('shares a dated file with everything and the currency', () async {
      await h.cubit.createBackup();

      expect(h.cubit.state, const BackupCreated());
      final file = h.sharer.shared.single;
      expect(file.name, 'spendwise-iq-backup-2026-11-21.json');
      expect(file.mimeType, 'application/json');
      final opened = await h.codec.decode(file.bytes);
      expect(opened.currencyCode, 'KES');
      expect(opened.expenses, hasLength(2));
    });

    test('with a password the file is locked', () async {
      await h.cubit.createBackup(password: 'secret1');

      final bytes = h.sharer.shared.single.bytes;
      expect(utf8.decode(bytes), isNot(contains('"expenses"')));
      expect(
        (await h.codec.decode(bytes, password: 'secret1')).expenses,
        hasLength(2),
      );
    });

    test('says so when the share sheet cannot open', () async {
      h.sharer.error = const ExportException(ExportProblem.couldNotShare);

      await h.cubit.createBackup();

      expect(h.cubit.state, const BackupFailed(BackupProblem.couldNotShare));
    });
  });

  group('restoring a backup', () {
    Future<void> chooseOwnBackup({String? password}) async {
      h.picker.bytes = await h.codec.encode(
        h.repository.data,
        password: password,
      );
      await h.cubit.chooseFile();
    }

    test('shows what is in the file before changing anything', () async {
      await chooseOwnBackup();

      final state = h.cubit.state as RestoreReady;
      expect(state.expenses, 2);
      expect(state.categories, 1);
      expect(h.repository.replaced, isNull);
    });

    test('replaces the data once the user agrees', () async {
      await chooseOwnBackup();

      await h.cubit.confirmRestore();

      expect(h.cubit.state, const RestoreDone(currencyCode: null));
      expect(h.repository.replaced, isNotNull);
    });

    test('hands the currency of the backup back to the screen', () async {
      final data = sampleData();
      h.picker.bytes = await h.codec.encode(
        sampleDataWithCurrency(data, 'USD'),
      );
      await h.cubit.chooseFile();

      await h.cubit.confirmRestore();

      expect(h.cubit.state, const RestoreDone(currencyCode: 'USD'));
    });

    test('does nothing when the user backs out of the picker', () async {
      h.picker.bytes = null;

      await h.cubit.chooseFile();

      expect(h.cubit.state, const BackupIdle());
    });

    test('reports a file that cannot be read', () async {
      h.picker.error = const BackupException(BackupProblem.couldNotRead);

      await h.cubit.chooseFile();

      expect(h.cubit.state, const BackupFailed(BackupProblem.couldNotRead));
    });

    test('refuses a file that is not a backup', () async {
      h.picker.bytes = Uint8List.fromList(utf8.encode('hello'));

      await h.cubit.chooseFile();

      expect(h.cubit.state, const BackupFailed(BackupProblem.notABackup));
      expect(h.repository.replaced, isNull);
    });

    test('asks for the password of a locked backup', () async {
      await chooseOwnBackup(password: 'secret1');

      expect(h.cubit.state, const RestoreNeedsPassword());
    });

    test('a wrong password asks again, the right one opens it', () async {
      await chooseOwnBackup(password: 'secret1');

      await h.cubit.openWithPassword('nope');
      expect(h.cubit.state, const RestoreNeedsPassword(wrongPassword: true));

      await h.cubit.openWithPassword('secret1');
      expect(h.cubit.state, isA<RestoreReady>());
    });

    test('a failed restore leaves the data as it was', () async {
      await chooseOwnBackup();
      h.repository.replaceError = StorageException(Exception('disk full'));

      await h.cubit.confirmRestore();

      expect(h.cubit.state, const BackupFailed(null));
      expect(h.repository.replaced, isNull);
    });

    test('a backup the database refuses is reported as damaged', () async {
      await chooseOwnBackup();
      h.repository.replaceError = const BackupException(BackupProblem.damaged);

      await h.cubit.confirmRestore();

      expect(h.cubit.state, const BackupFailed(BackupProblem.damaged));
    });

    test('cannot restore before a file was opened', () async {
      await h.cubit.confirmRestore();

      expect(h.cubit.state, const BackupIdle());
    });

    test('reset forgets the chosen file', () async {
      await chooseOwnBackup();

      h.cubit.reset();
      await h.cubit.confirmRestore();

      expect(h.cubit.state, const BackupIdle());
      expect(h.repository.replaced, isNull);
    });
  });
}
