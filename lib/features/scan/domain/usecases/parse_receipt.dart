import '../entities/receipt_draft.dart';
import '../parsing/receipt_amounts.dart';
import '../parsing/receipt_dates.dart';
import '../parsing/receipt_vendors.dart';

/// Turns the text lines read from a receipt photo into a draft: the vendor,
/// the date and the total. Each part is found on its own, so a receipt with
/// a smudged date still gives a vendor and a total.
///
/// The lines come from OCR, top to bottom. The result is only a starting
/// point: the user checks it in the expense form before saving.
class ParseReceipt {
  ParseReceipt({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  ReceiptDraft call(List<String> lines) {
    // Blank lines carry nothing, and the parsers read neighbouring lines.
    final text = [
      for (final line in lines)
        if (line.trim().isNotEmpty) line.trim(),
    ];

    final total = ReceiptAmounts.findTotal(text);
    return ReceiptDraft(
      vendor: ReceiptVendors.find(text),
      date: ReceiptDates.find(text, _now()),
      totalMinor: total?.minor,
      totalIsGuess: total?.isGuess ?? false,
    );
  }
}
