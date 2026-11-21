import 'package:equatable/equatable.dart';

/// What kind of M-Pesa message it was.
enum MpesaKind {
  /// Money sent to a person.
  sentToPerson,

  /// A paybill payment: a business and an account number.
  paybill,

  /// A payment at a till (buy goods).
  till,

  /// Airtime bought.
  airtime,

  /// Cash taken out at an agent.
  withdrawal,

  /// Money that came in. Not an expense.
  received,

  /// A confirmation the parser does not know the shape of, but with an amount.
  other,
}

/// What was read from an M-Pesa confirmation message.
class MpesaTransaction extends Equatable {
  const MpesaTransaction({
    required this.kind,
    required this.amountMinor,
    this.code,
    this.counterparty = '',
    this.account = '',
    this.date,
    this.costMinor,
  });

  final MpesaKind kind;

  /// What was sent or paid, in minor units (cents).
  final int amountMinor;

  /// The transaction code, such as "SGH4A1B2C3", or null when not found.
  final String? code;

  /// Who or what was paid: a person, a business or an agent.
  final String counterparty;

  /// The account number of a paybill payment.
  final String account;

  /// The day it happened, or null when the message did not say.
  final DateTime? date;

  /// The transaction cost M-Pesa charged on top, or null when none was shown.
  final int? costMinor;

  /// True for money that came in, which this app does not record.
  bool get isIncome => kind == MpesaKind.received;

  @override
  List<Object?> get props => [
    kind,
    amountMinor,
    code,
    counterparty,
    account,
    date,
    costMinor,
  ];
}
