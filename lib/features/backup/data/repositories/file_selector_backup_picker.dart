// coverage:ignore-file
// The only code that opens the Files app for a backup. It needs a real phone,
// so it stays as small as possible and the logic around it is tested with a
// fake.
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/backup_exception.dart';
import '../../domain/repositories/backup_file_picker.dart';

/// Picks a backup with Android's document picker. Like the receipt picker, it
/// hands the app only the file the user taps, so no storage permission is
/// asked for.
class FileSelectorBackupPicker implements BackupFilePicker {
  const FileSelectorBackupPicker();

  String get _markerPath =>
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'spendwise_choosing_backup';

  @override
  Future<Uint8List?> pick() async {
    // Left behind if Android closes the app while the Files app is open, so
    // the next start knows the choice was lost.
    await _writeMarker();
    try {
      // Any file: a backup shared by another app may not keep its extension.
      final file = await openFile();
      if (file == null) return null;
      return await file.readAsBytes();
    } on Exception {
      throw const BackupException(BackupProblem.couldNotRead);
    } finally {
      await _deleteMarker();
    }
  }

  @override
  Future<bool> pickWasInterrupted() async {
    final marker = File(_markerPath);
    try {
      if (!await marker.exists()) return false;
      await marker.delete();
      return true;
    } on Exception {
      return false;
    }
  }

  Future<void> _writeMarker() async {
    try {
      await File(_markerPath).writeAsString('');
    } on Exception {
      // Only a courtesy message depends on it, so carry on without.
    }
  }

  Future<void> _deleteMarker() async {
    try {
      final marker = File(_markerPath);
      if (await marker.exists()) await marker.delete();
    } on Exception {
      // Already gone.
    }
  }
}
