/// The kinds of report the user can export.
enum ExportFormat {
  pdf(extension: 'pdf', mimeType: 'application/pdf'),
  csv(extension: 'csv', mimeType: 'text/csv');

  const ExportFormat({required this.extension, required this.mimeType});

  /// File name ending, without the dot.
  final String extension;
  final String mimeType;
}
