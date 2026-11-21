// coverage:ignore-file
// The only code that opens the Files app. It needs a real phone, so it stays as
// small as possible and the logic around it is tested with a fake.
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/scan_exception.dart';
import 'file_chooser.dart';

/// Picks a receipt with Android's document picker (the Files app), through
/// `file_selector`.
///
/// The system draws the picker and hands this app only the file the user
/// taps, so no storage permission is asked for. Unlike the photo picker, it
/// also lists PDFs and everything in Downloads, Drive and other apps' folders.
class FileSelectorChooser implements FileChooser {
  const FileSelectorChooser();

  static const _receipts = XTypeGroup(
    label: 'Receipts',
    extensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
    mimeTypes: ['application/pdf', 'image/*'],
    uniformTypeIdentifiers: ['com.adobe.pdf', 'public.image'],
  );

  @override
  Future<String?> chooseFile() async {
    try {
      final file = await openFile(acceptedTypeGroups: const [_receipts]);
      return file?.path;
    } on PlatformException catch (e) {
      throw ScanException(ScanProblem.cannotOpenFile, e);
    }
  }
}
