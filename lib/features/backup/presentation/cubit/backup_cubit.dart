import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../domain/backup_exception.dart';
import '../../domain/entities/backup_data.dart';
import '../../domain/repositories/backup_file_picker.dart';
import '../../domain/usecases/create_backup.dart';
import '../../domain/usecases/restore_backup.dart';
import 'backup_state.dart';

/// Drives backing up and restoring. A restore goes in steps: choose a file,
/// give its password if it has one, see what is in it, then agree.
class BackupCubit extends Cubit<BackupState> {
  BackupCubit(this._create, this._restore, this._picker)
    : super(const BackupIdle());

  final CreateBackup _create;
  final RestoreBackup _restore;
  final BackupFilePicker _picker;

  Uint8List? _file;
  BackupData? _data;

  bool get _busy => state is BackupWorking;

  /// [password] locks the file. Blank means no password.
  Future<void> createBackup({String? password}) async {
    if (_busy) return;
    emit(const BackupWorking());
    switch (await _create(password: password)) {
      case Success():
        emit(const BackupCreated());
      case Failure(failure: final BackupFailure failure):
        emit(BackupFailed(failure.problem));
      case Failure():
        emit(const BackupFailed(null));
    }
  }

  /// Opens the Files app to choose a backup.
  Future<void> chooseFile() async {
    if (_busy) return;
    emit(const BackupWorking());

    final Uint8List? bytes;
    try {
      bytes = await _picker.pick();
    } on BackupException catch (e) {
      emit(BackupFailed(e.problem));
      return;
    }
    if (bytes == null) {
      emit(const BackupIdle());
      return;
    }
    _file = bytes;
    _data = null;

    switch (_restore.inspect(bytes)) {
      case Success(value: BackupLock.needsPassword):
        emit(const RestoreNeedsPassword());
      case Success():
        await _open(null);
      case Failure(failure: final BackupFailure failure):
        emit(BackupFailed(failure.problem));
      case Failure():
        emit(const BackupFailed(null));
    }
  }

  /// Tries the password on the chosen file.
  Future<void> openWithPassword(String password) async {
    if (_busy || _file == null) return;
    emit(const BackupWorking());
    await _open(password);
  }

  Future<void> _open(String? password) async {
    final bytes = _file;
    if (bytes == null) return;
    switch (await _restore.open(bytes, password: password)) {
      case Success(value: final data):
        _data = data;
        emit(
          RestoreReady(
            createdAt: data.createdAt,
            expenses: data.expenses.length,
            categories: data.categories.length,
            budgets: data.budgets.length,
            recurringRules: data.recurringRules.length,
          ),
        );
      case Failure(
        failure: BackupFailure(problem: BackupProblem.wrongPassword),
      ):
        emit(const RestoreNeedsPassword(wrongPassword: true));
      case Failure(failure: final BackupFailure failure):
        emit(BackupFailed(failure.problem));
      case Failure():
        emit(const BackupFailed(null));
    }
  }

  /// The user has seen what is in the backup and agreed to replace their data.
  Future<void> confirmRestore() async {
    final data = _data;
    if (_busy || data == null) return;
    emit(const BackupWorking());
    switch (await _restore.restore(data)) {
      case Success():
        _forget();
        emit(RestoreDone(currencyCode: data.currencyCode));
      case Failure(failure: final BackupFailure failure):
        emit(BackupFailed(failure.problem));
      case Failure():
        emit(const BackupFailed(null));
    }
  }

  /// Drops the chosen file and goes back to the start.
  void reset() {
    _forget();
    emit(const BackupIdle());
  }

  void _forget() {
    _file = null;
    _data = null;
  }
}
