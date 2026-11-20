/// Turns the first page of a PDF into an image.
abstract interface class PdfPageRenderer {
  /// Draws page one of the PDF at [pdfPath] into a PNG file at [imagePath].
  /// Throws [PdfRenderException] when the PDF cannot be opened or drawn, for
  /// example because it is protected with a password or damaged.
  Future<void> renderFirstPage(String pdfPath, String imagePath);
}

class PdfRenderException implements Exception {
  const PdfRenderException(this.cause);

  final Object cause;

  @override
  String toString() => 'PdfRenderException: $cause';
}
