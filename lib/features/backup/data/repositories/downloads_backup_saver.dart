// coverage:ignore-file
// The only code that writes into the phone's Downloads folder. It needs a real
// phone, so it stays as small as possible and the logic around it is tested
// with a fake.
import 'package:flutter/services.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../export/domain/entities/report_file.dart';
import '../../../export/domain/export_exception.dart';
import '../../../export/domain/repositories/report_sharer.dart';

/// Saves a file straight into the Downloads folder, with no share sheet. On a
/// phone older than Android 10, which cannot do that without a storage
/// permission, it opens the share sheet instead.
class DownloadsBackupSaver implements ReportSharer {
  const DownloadsBackupSaver({required this.fallback});

  static const _channel = MethodChannel('com.bornmajor.spendwiseiq/downloads');

  /// Used when the phone cannot save to Downloads directly.
  final ReportSharer fallback;

  @override
  Future<void> share(ReportFile file) async {
    try {
      await _channel.invokeMethod<void>('save', {
        'name': file.name,
        'mimeType': file.mimeType,
        'bytes': file.bytes,
      });
    } on PlatformException catch (e) {
      if (e.code == 'unsupported') return fallback.share(file);
      throw const ExportException(ExportProblem.couldNotShare);
    } on MissingPluginException {
      return fallback.share(file);
    }
  }
}
