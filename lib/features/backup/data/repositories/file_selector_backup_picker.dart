// coverage:ignore-file
// The only code that opens the Files app for a backup. It needs a real phone,
// so it stays as small as possible and the logic around it is tested with a
// fake.
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

  @override
  Future<Uint8List?> pick() async {
    try {
      // Any file: a backup shared by another app may not keep its extension.
      final file = await openFile();
      if (file == null) return null;
      return await file.readAsBytes();
    } on Exception {
      throw const BackupException(BackupProblem.couldNotRead);
    }
  }
}
