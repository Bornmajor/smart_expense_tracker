// coverage:ignore-file
// The only code that opens the system share sheet. It needs a real device, so
// it stays as small as possible and the logic around it is tested with a fake.
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/report_file.dart';
import '../../domain/export_exception.dart';
import '../../domain/repositories/report_sharer.dart';

class SharePlusReportSharer implements ReportSharer {
  const SharePlusReportSharer();

  @override
  Future<void> share(ReportFile file) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              file.bytes,
              mimeType: file.mimeType,
              name: file.name,
            ),
          ],
          fileNameOverrides: [file.name],
          subject: file.name,
        ),
      );
    } on PlatformException {
      throw const ExportException(ExportProblem.couldNotShare);
    }
  }
}
