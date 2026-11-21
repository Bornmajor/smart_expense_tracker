import 'dart:typed_data';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../../export/domain/entities/report_file.dart';
import '../../../export/domain/export_exception.dart';
import '../../../export/domain/repositories/report_sharer.dart';
import '../backup_codec.dart';
import '../backup_exception.dart';
import '../entities/backup_data.dart';
import '../repositories/backup_history.dart';
import '../repositories/backup_repository.dart';

/// Makes a backup file of everything in the app and saves it to the phone's
/// Downloads folder, from where the user can copy it to Drive or send it to
/// themselves. (On a phone too old to save there directly, the share sheet
/// opens instead.)
class CreateBackup {
  CreateBackup({
    required this._repository,
    required this._codec,
    required this._sharer,
    required this._currencyCode,
    required this._history,
  });

  final BackupRepository _repository;
  final BackupCodec _codec;
  final ReportSharer _sharer;
  final BackupHistory _history;

  /// The currency on screen right now (such as "KES"), or null for plain
  /// numbers. Read each time because the user can change it.
  final String? Function() _currencyCode;

  /// With a non-empty [password] the file is locked with it, and cannot be
  /// opened without it. There is no way to recover a lost password.
  Future<Result<void>> call({String? password}) async {
    try {
      final read = await _repository.read();
      final data = BackupData(
        version: read.version,
        createdAt: read.createdAt,
        currencyCode: _currencyCode(),
        categories: read.categories,
        expenses: read.expenses,
        budgets: read.budgets,
        recurringRules: read.recurringRules,
      );
      final Uint8List bytes = await _codec.encode(data, password: password);

      final day = read.createdAt;
      final name =
          'spendwise-iq-backup-${day.year}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}.json';
      await _sharer.share(
        ReportFile(name: name, mimeType: 'application/json', bytes: bytes),
      );
      await _history.record(read.createdAt);
      return const Success(null);
    } on StorageException {
      return const Failure(StorageFailure());
    } on ExportException {
      return const Failure(BackupFailure(BackupProblem.couldNotShare));
    } on BackupException catch (e) {
      return Failure(BackupFailure(e.problem));
    }
  }
}
