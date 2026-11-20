// coverage:ignore-file
// The only code that draws a PDF. It needs a real phone, so it stays as small
// as possible and the logic around it is tested with a fake.
import 'dart:io';
import 'dart:math' as math;

import 'package:pdfx/pdfx.dart';

import 'pdf_page_renderer.dart';

/// Draws a PDF page with `pdfx`, which uses the phone's own PDF renderer.
class PdfxPageRenderer implements PdfPageRenderer {
  const PdfxPageRenderer();

  /// Big enough for small print on a receipt to stay sharp, small enough to
  /// draw and read quickly on a phone with little memory.
  static const _targetWidth = 2000.0;
  static const _maxHeight = 3000.0;

  @override
  Future<void> renderFirstPage(String pdfPath, String imagePath) async {
    try {
      final document = await PdfDocument.openFile(pdfPath);
      try {
        final page = await document.getPage(1);
        try {
          final scale = math.min(
            _targetWidth / page.width,
            _maxHeight / page.height,
          );
          final image = await page.render(
            width: page.width * scale,
            height: page.height * scale,
            format: PdfPageImageFormat.png,
            // A PDF page is transparent, which would read as black.
            backgroundColor: '#FFFFFF',
          );
          if (image == null) {
            throw const PdfRenderException('The page could not be drawn');
          }
          await File(imagePath).writeAsBytes(image.bytes);
        } finally {
          await page.close();
        }
      } finally {
        await document.close();
      }
    } on PdfRenderException {
      rethrow;
    } on Object catch (error) {
      throw PdfRenderException(error);
    }
  }
}
