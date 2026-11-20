import 'package:flutter/services.dart';

import 'pdf_report_writer.dart';

/// Reads the Inter font files that ship inside the app (see pubspec.yaml).
Future<PdfFontBytes> loadBundledFonts() async {
  Future<Uint8List> read(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  return (
    regular: await read('assets/fonts/Inter-Regular.ttf'),
    bold: await read('assets/fonts/Inter-Bold.ttf'),
  );
}
