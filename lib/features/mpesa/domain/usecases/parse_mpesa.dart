import '../../../../core/utils/money.dart';
import '../entities/mpesa_transaction.dart';

/// Reads an M-Pesa confirmation message pasted by the user. Plain rules on the
/// phone: nothing is sent anywhere, and the app never reads the user's SMS.
///
/// It knows the usual English confirmations: sent to a person, paybill, till
/// payment, airtime, withdrawal and money received. A message of another shape
/// that still has an amount in Ksh is read as [MpesaKind.other], and a message
/// with no amount gives null. It only reads; the user checks the form.
class ParseMpesa {
  const ParseMpesa();

  static const _amount = r'Ksh\.?\s*([\d,]+(?:\.\d{1,2})?)';
  static const _day = r'(\d{1,2})/(\d{1,2})/(\d{2,4})';

  static final _code = RegExp(
    r'\b([A-Z][A-Z0-9]{9})\s+confirmed',
    caseSensitive: false,
  );
  static final _when = RegExp(
    '\\bon\\s+$_day(?:\\s+at\\s+\\d{1,2}:\\d{2}\\s*[AP]M)?',
    caseSensitive: false,
  );
  static final _cost = RegExp(
    'transaction\\s+cost,?\\s*$_amount',
    caseSensitive: false,
  );

  static final _received = RegExp(
    'you\\s+have\\s+received\\s+$_amount\\s+from\\s+(.+?)\\s+on\\s+$_day',
    caseSensitive: false,
  );
  static final _airtime = RegExp(
    'you\\s+bought\\s+$_amount\\s+of\\s+airtime',
    caseSensitive: false,
  );
  static final _withdraw = RegExp(
    'withdraw\\s+$_amount\\s+from\\s+(\\d+)\\s*-\\s*(.+?)\\s+new\\s+m-?pesa',
    caseSensitive: false,
  );
  static final _paid = RegExp(
    '$_amount\\s+paid\\s+to\\s+(.+?)\\.?\\s+on\\s+$_day',
    caseSensitive: false,
  );
  static final _sent = RegExp(
    '$_amount\\s+sent\\s+to\\s+(.+?)(?:\\s+for\\s+account\\s+(\\S+?))?'
    '\\s+on\\s+$_day',
    caseSensitive: false,
  );
  static final _anyAmount = RegExp(_amount, caseSensitive: false);

  /// The transaction in [message], or null when it has no amount in Ksh.
  MpesaTransaction? call(String message) {
    final text = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return null;

    final code = _code.firstMatch(text)?.group(1)?.toUpperCase();
    final date = _date(text);
    final cost = _money(_cost.firstMatch(text)?.group(1));

    final received = _received.firstMatch(text);
    if (received != null) {
      return _make(
        MpesaKind.received,
        received.group(1)!,
        code: code,
        date: date,
        counterparty: _name(received.group(2)!),
      );
    }

    final airtime = _airtime.firstMatch(text);
    if (airtime != null) {
      return _make(
        MpesaKind.airtime,
        airtime.group(1)!,
        code: code,
        date: date,
        cost: cost,
        counterparty: 'Safaricom',
      );
    }

    final withdraw = _withdraw.firstMatch(text);
    if (withdraw != null) {
      return _make(
        MpesaKind.withdrawal,
        withdraw.group(1)!,
        code: code,
        date: date,
        cost: cost,
        counterparty: _name(withdraw.group(3)!),
        account: withdraw.group(2)!,
      );
    }

    final paid = _paid.firstMatch(text);
    if (paid != null) {
      return _make(
        MpesaKind.till,
        paid.group(1)!,
        code: code,
        date: date,
        cost: cost,
        counterparty: _name(paid.group(2)!),
      );
    }

    final sent = _sent.firstMatch(text);
    if (sent != null) {
      final account = sent.group(3);
      return _make(
        account == null ? MpesaKind.sentToPerson : MpesaKind.paybill,
        sent.group(1)!,
        code: code,
        date: date,
        cost: cost,
        counterparty: _name(sent.group(2)!),
        account: account ?? '',
      );
    }

    // Some other message with an amount: still better than starting empty.
    final any = _anyAmount.firstMatch(text);
    if (any == null) return null;
    return _make(MpesaKind.other, any.group(1)!, code: code, date: date);
  }

  MpesaTransaction? _make(
    MpesaKind kind,
    String amount, {
    String? code,
    DateTime? date,
    int? cost,
    String counterparty = '',
    String account = '',
  }) {
    final minor = _money(amount);
    if (minor == null || minor <= 0) return null;
    return MpesaTransaction(
      kind: kind,
      amountMinor: minor,
      code: code,
      counterparty: counterparty,
      account: account,
      date: date,
      costMinor: cost != null && cost > 0 ? cost : null,
    );
  }

  int? _money(String? text) =>
      text == null ? null : Money.tryParse(text.replaceAll(',', ''));

  DateTime? _date(String text) {
    final match = _when.firstMatch(text);
    if (match == null) return null;
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final fullYear = year < 100 ? 2000 + year : year;
    final date = DateTime(fullYear, month, day);
    // Rejects something like 31/2, which DateTime would roll into March.
    if (date.month != month || date.day != day) return null;
    return date;
  }

  /// "JOHN DOE 0712345678" becomes "John Doe": no phone number, no shouting.
  String _name(String raw) {
    final withoutNumber = raw
        .replaceAll(RegExp(r'\b(?:\+?254|0)\d{8,9}\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\s.\-]+|[\s.\-]+$'), '')
        .trim();
    if (withoutNumber != withoutNumber.toUpperCase()) return withoutNumber;
    return withoutNumber
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
