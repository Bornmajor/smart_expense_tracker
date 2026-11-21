import 'dart:typed_data';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../backup_codec.dart';
import '../backup_exception.dart';
import '../entities/backup_data.dart';
import '../repositories/backup_repository.dart';

/// Whether a chosen file needs a password before it can be opened.
enum BackupLock { open, needsPassword }

/// Opens a backup file and, once the user has seen what is in it and agreed,
/// replaces everything on this phone with it.
class RestoreBackup {
  const RestoreBackup(this._repository, this._codec);

  final BackupRepository _repository;
  final BackupCodec _codec;

  /// First look at a chosen file: is it a backup, and is it locked?
  Result<BackupLock> inspect(Uint8List bytes) {
    try {
      return Success(
        _codec.isEncrypted(bytes) ? BackupLock.needsPassword : BackupLock.open,
      );
    } on BackupException catch (e) {
      return Failure(BackupFailure(e.problem));
    }
  }

  /// Reads what is in the file, with the [password] when it is locked. This
  /// changes nothing on the phone.
  Future<Result<BackupData>> open(Uint8List bytes, {String? password}) async {
    try {
      return Success(await _codec.decode(bytes, password: password));
    } on BackupException catch (e) {
      return Failure(BackupFailure(e.problem));
    }
  }

  /// Replaces everything on this phone with [data]. Either all of it is
  /// restored or nothing is changed.
  Future<Result<void>> restore(BackupData data) async {
    try {
      await _repository.replaceAll(data);
      return const Success(null);
    } on BackupException catch (e) {
      return Failure(BackupFailure(e.problem));
    } on StorageException {
      return const Failure(StorageFailure());
    }
  }
}
