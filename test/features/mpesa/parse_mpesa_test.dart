import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/mpesa/domain/entities/mpesa_transaction.dart';
import 'package:smart_expense_tracker/features/mpesa/domain/usecases/parse_mpesa.dart';

/// Messages in the shape M-Pesa sends, with made-up names, numbers and codes.
void main() {
  const parse = ParseMpesa();

  const sent =
      'SGH4A1B2C3 Confirmed. Ksh500.00 sent to JOHN DOE 0712345678 on '
      '17/7/26 at 2:15 PM. New M-PESA balance is Ksh1,234.56. Transaction '
      'cost, Ksh7.00. Amount you can transact within the day is 499,500.00.';

  const paybill =
      'SGH4A1B2C4 Confirmed. Ksh1,200.00 sent to KPLC PREPAID for account '
      '12345678 on 3/11/26 at 9:05 AM New M-PESA balance is Ksh900.00. '
      'Transaction cost, Ksh33.00.';

  const till =
      'SGH4A1B2C5 Confirmed. Ksh350.00 paid to JAVA HOUSE. on 20/11/26 at '
      '1:30 PM.New M-PESA balance is Ksh2,000.00. Transaction cost, Ksh0.00.';

  const airtime =
      'SGH4A1B2C6 confirmed. You bought Ksh100.00 of airtime on 21/11/26 at '
      '8:00 AM.New M-PESA balance is Ksh500.00. Transaction cost, Ksh0.00.';

  const withdraw =
      'SGH4A1B2C7 Confirmed.on 5/11/26 at 6:45 PM Withdraw Ksh1,000.00 from '
      '123456 - MAMA MBOGA SHOP New M-PESA balance is Ksh300.00. Transaction '
      'cost, Ksh28.00.';

  const received =
      'SGH4A1B2C8 Confirmed.You have received Ksh2,500.00 from JANE ROE '
      '0722000000 on 18/11/26 at 10:10 AM. New M-PESA balance is Ksh4,000.00.';

  group('a payment to a person', () {
    test('has the amount, name, date, code and cost', () {
      final result = parse(sent)!;

      expect(result.kind, MpesaKind.sentToPerson);
      expect(result.amountMinor, 50000);
      expect(result.counterparty, 'John Doe');
      expect(result.date, DateTime(2026, 7, 17));
      expect(result.code, 'SGH4A1B2C3');
      expect(result.costMinor, 700);
    });

    test('keeps the phone number out of the name', () {
      expect(parse(sent)!.counterparty, isNot(contains('0712')));
    });
  });

  test('a paybill payment has the business and the account', () {
    final result = parse(paybill)!;

    expect(result.kind, MpesaKind.paybill);
    expect(result.amountMinor, 120000);
    expect(result.counterparty, 'Kplc Prepaid');
    expect(result.account, '12345678');
    expect(result.date, DateTime(2026, 11, 3));
    expect(result.costMinor, 3300);
  });

  test('a till payment has the shop and no cost when it is zero', () {
    final result = parse(till)!;

    expect(result.kind, MpesaKind.till);
    expect(result.amountMinor, 35000);
    expect(result.counterparty, 'Java House');
    expect(result.costMinor, isNull);
    expect(result.date, DateTime(2026, 11, 20));
  });

  test('airtime is paid to Safaricom', () {
    final result = parse(airtime)!;

    expect(result.kind, MpesaKind.airtime);
    expect(result.amountMinor, 10000);
    expect(result.counterparty, 'Safaricom');
    expect(result.code, 'SGH4A1B2C6');
  });

  test('a withdrawal has the agent', () {
    final result = parse(withdraw)!;

    expect(result.kind, MpesaKind.withdrawal);
    expect(result.amountMinor, 100000);
    expect(result.counterparty, 'Mama Mboga Shop');
    expect(result.account, '123456');
    expect(result.costMinor, 2800);
    expect(result.date, DateTime(2026, 11, 5));
  });

  test('money received is recognised as income', () {
    final result = parse(received)!;

    expect(result.kind, MpesaKind.received);
    expect(result.isIncome, isTrue);
    expect(result.amountMinor, 250000);
    expect(result.counterparty, 'Jane Roe');
  });

  group('messages of other shapes', () {
    test('still give the amount when there is one', () {
      final result = parse(
        'SGH4A1B2C9 Confirmed. Ksh75.50 was charged for something new on '
        '1/12/26 at 7:00 AM.',
      )!;

      expect(result.kind, MpesaKind.other);
      expect(result.amountMinor, 7550);
      expect(result.code, 'SGH4A1B2C9');
      expect(result.date, DateTime(2026, 12, 1));
    });

    test('give nothing when there is no amount', () {
      expect(parse('Hello, how are you?'), isNull);
      expect(parse(''), isNull);
      expect(parse('   '), isNull);
    });
  });

  group('how the text arrives', () {
    test('line breaks and extra spaces do not matter', () {
      final result = parse(sent.replaceAll('. ', '.\n  '))!;

      expect(result.kind, MpesaKind.sentToPerson);
      expect(result.amountMinor, 50000);
    });

    test('capitals do not matter', () {
      expect(parse(sent.toUpperCase())!.amountMinor, 50000);
    });

    test('a four digit year and a lone day work', () {
      final result = parse(
        'SGH4A1B2D1 Confirmed. Ksh10.00 sent to SAM LEE 0700000000 on '
        '1/2/2026 at 1:00 AM.',
      )!;

      expect(result.date, DateTime(2026, 2, 1));
    });

    test('an impossible date is left out', () {
      final result = parse(
        'SGH4A1B2D2 Confirmed. Ksh10.00 sent to SAM LEE 0700000000 on '
        '31/2/26 at 1:00 AM.',
      )!;

      expect(result.date, isNull);
      expect(result.amountMinor, 1000);
    });
  });
}
