import '../entities/ocr_line.dart';

/// Rebuilds the rows of a receipt from the lines OCR found.
///
/// On a printed receipt the item name sits on the left and the price on the
/// right, and OCR often reports them as two separate lines. The parsers expect
/// "TOTAL 1,160.00" together, so lines that sit at the same height are joined,
/// left to right, into one row.
abstract final class ReceiptRows {
  /// How far apart, as a share of a line's height, two lines' centres may be
  /// and still count as the same row.
  static const _sameRowTolerance = 0.6;

  static List<String> build(List<OcrLine> lines) {
    final usable = [
      for (final line in lines)
        if (line.text.trim().isNotEmpty && line.height > 0) line,
    ]..sort((a, b) => a.centerY.compareTo(b.centerY));

    final rows = <List<OcrLine>>[];
    for (final line in usable) {
      if (rows.isNotEmpty && _sameRow(rows.last, line)) {
        rows.last.add(line);
      } else {
        rows.add([line]);
      }
    }

    return [
      for (final row in rows)
        (row..sort((a, b) => a.left.compareTo(b.left)))
            .map((line) => line.text.trim())
            .join(' '),
    ];
  }

  /// A line belongs to the row when its centre is within a little of the
  /// row's average centre, measured against the smaller of the two heights.
  static bool _sameRow(List<OcrLine> row, OcrLine line) {
    final rowCenter =
        row.map((l) => l.centerY).reduce((a, b) => a + b) / row.length;
    final rowHeight = row.map((l) => l.height).reduce((a, b) => a < b ? a : b);
    final smaller = rowHeight < line.height ? rowHeight : line.height;
    return (line.centerY - rowCenter).abs() <= smaller * _sameRowTolerance;
  }
}
