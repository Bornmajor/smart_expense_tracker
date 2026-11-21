import 'dart:typed_data';

import 'package:smart_expense_tracker/features/backup/data/crypto/cryptography_backup_cipher.dart';
import 'package:smart_expense_tracker/features/backup/domain/backup_codec.dart';
import 'package:smart_expense_tracker/features/backup/domain/backup_exception.dart';
import 'package:smart_expense_tracker/features/backup/domain/entities/backup_data.dart';
import 'package:smart_expense_tracker/features/backup/domain/repositories/backup_file_picker.dart';
import 'package:smart_expense_tracker/features/backup/domain/repositories/backup_history.dart';
import 'package:smart_expense_tracker/features/backup/domain/repositories/backup_repository.dart';
import 'package:smart_expense_tracker/features/backup/domain/repositories/local_state_reset.dart';
import 'package:smart_expense_tracker/features/backup/domain/usecases/create_backup.dart';
import 'package:smart_expense_tracker/features/backup/domain/usecases/restore_backup.dart';
import 'package:smart_expense_tracker/features/backup/presentation/cubit/backup_cubit.dart';

import '../../support/fakes.dart';

/// Holds the backup data in memory instead of a database.
class FakeBackupRepository implements BackupRepository {
  FakeBackupRepository({BackupData? data}) : data = data ?? sampleData();

  BackupData data;

  /// When set, `replaceAll` throws it and nothing changes.
  Object? replaceError;

  /// The data passed to the last `replaceAll`, or null if none.
  BackupData? replaced;

  @override
  Future<BackupData> read() async => data;

  /// Set to make `eraseAll` throw it.
  Object? eraseError;

  /// How many times `eraseAll` worked.
  int erased = 0;

  @override
  Future<void> eraseAll() async {
    final error = eraseError;
    if (error != null) throw error;
    erased++;
  }

  @override
  Future<void> replaceAll(BackupData data) async {
    final error = replaceError;
    if (error != null) throw error;
    replaced = data;
    this.data = data;
  }
}

class FakeBackupFilePicker implements BackupFilePicker {
  /// What the user chose. Null means they backed out.
  Uint8List? bytes;

  /// When set, `pick` throws it.
  BackupException? error;

  int picks = 0;

  /// Whether the last start found a choice that Android cut short.
  bool interrupted = false;

  @override
  Future<bool> pickWasInterrupted() async {
    final was = interrupted;
    interrupted = false;
    return was;
  }

  @override
  Future<Uint8List?> pick() async {
    picks++;
    final failure = error;
    if (failure != null) throw failure;
    return bytes;
  }
}

BackupData sampleData() => BackupData(
  version: BackupData.currentVersion,
  createdAt: DateTime(2026, 11, 21, 9),
  categories: const [
    {'id': 'other', 'name': 'Other'},
  ],
  expenses: const [
    {'id': 'e1'},
    {'id': 'e2'},
  ],
  budgets: const [],
  recurringRules: const [],
);

/// A cipher with few rounds, so tests are quick.
BackupCodec testCodec() => BackupCodec(CryptographyBackupCipher(iterations: 2));

/// Everything a backup test needs, wired together.
class BackupHarness {
  BackupHarness({String? currency = 'KES', BackupData? data})
    : repository = FakeBackupRepository(data: data),
      codec = testCodec() {
    final restore = RestoreBackup(repository, codec);
    cubit = BackupCubit(
      CreateBackup(
        repository: repository,
        codec: codec,
        sharer: sharer,
        currencyCode: () => currency,
        history: history,
      ),
      restore,
      picker,
    );
  }

  final FakeBackupRepository repository;
  final BackupCodec codec;
  final sharer = FakeReportSharer();
  final history = FakeBackupHistory();
  final picker = FakeBackupFilePicker();
  late final BackupCubit cubit;
}

/// [data] with another currency.
BackupData sampleDataWithCurrency(BackupData data, String code) => BackupData(
  version: data.version,
  createdAt: data.createdAt,
  currencyCode: code,
  categories: data.categories,
  expenses: data.expenses,
  budgets: data.budgets,
  recurringRules: data.recurringRules,
);

/// Remembers the last backup in memory.
class FakeBackupHistory implements BackupHistory {
  DateTime? last;

  @override
  DateTime? lastBackupAt() => last;

  @override
  Future<void> record(DateTime when) async => last = when;
}

/// Counts how often the app's remembered state was cleared.
class FakeLocalStateReset implements LocalStateReset {
  int cleared = 0;

  @override
  Future<void> clear() async => cleared++;
}
