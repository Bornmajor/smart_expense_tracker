import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/scan/domain/parsing/receipt_dates.dart';

void main() {
  // "Today" in these tests: 18 November 2026.
  final now = DateTime(2026, 11, 18, 15, 30);

  DateTime? find(List<String> lines) => ReceiptDates.find(lines, now);

  group('numeric dates are read day-first', () {
    test('with slashes, dashes and dots', () {
      expect(find(['16/11/2026']), DateTime(2026, 11, 16));
      expect(find(['16-11-2026']), DateTime(2026, 11, 16));
      expect(find(['16.11.2026']), DateTime(2026, 11, 16));
    });

    test('with a two-digit year', () {
      expect(find(['16/11/26']), DateTime(2026, 11, 16));
    });

    test('with single-digit days and months', () {
      expect(find(['3/4/2026']), DateTime(2026, 4, 3));
    });

    test('03/04/2026 is 3 April, not 4 March', () {
      expect(find(['03/04/2026']), DateTime(2026, 4, 3));
    });

    test('inside a line with other text and a time', () {
      expect(find(['Date: 16/11/2026 14:35']), DateTime(2026, 11, 16));
      expect(find(['SAT 16/11/2026 08:12:45 POS3']), DateTime(2026, 11, 16));
    });
  });

  group('the other order is the second try', () {
    test('11/16/2026 can only be month-first, so it is 16 November', () {
      expect(find(['11/16/2026']), DateTime(2026, 11, 16));
    });

    test('a day-first date in the future falls back to month-first', () {
      // Day-first: 11 December 2026, which has not happened yet.
      expect(find(['11/12/2026']), DateTime(2026, 11, 12));
    });

    test('keeps day-first when both orders are in the past', () {
      expect(find(['05/06/2026']), DateTime(2026, 6, 5));
    });
  });

  group('year first', () {
    test('with dashes and slashes', () {
      expect(find(['2026-11-16']), DateTime(2026, 11, 16));
      expect(find(['2026/11/16']), DateTime(2026, 11, 16));
    });

    test('with an ISO timestamp', () {
      expect(find(['2026-11-16T14:35:00']), DateTime(2026, 11, 16));
    });
  });

  group('month names', () {
    test('day, month name, year', () {
      expect(find(['16 Nov 2026']), DateTime(2026, 11, 16));
      expect(find(['16 November 2026']), DateTime(2026, 11, 16));
      expect(find(['16-Nov-2026']), DateTime(2026, 11, 16));
      expect(find(['16th November, 2026']), DateTime(2026, 11, 16));
      expect(find(['16 NOV 26']), DateTime(2026, 11, 16));
    });

    test('month name, day, year', () {
      expect(find(['Nov 16, 2026']), DateTime(2026, 11, 16));
      expect(find(['November 16 2026']), DateTime(2026, 11, 16));
      expect(find(['NOVEMBER 16TH, 2026']), DateTime(2026, 11, 16));
    });

    test('every month is understood, including Sept', () {
      const names = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      for (var i = 0; i < names.length; i++) {
        expect(
          find(['3 ${names[i]} 2025']),
          DateTime(2025, i + 1, 3),
          reason: names[i],
        );
      }
      expect(find(['3 Sept 2025']), DateTime(2025, 9, 3));
    });
  });

  group('dates that are rejected', () {
    test('a date that does not exist', () {
      expect(find(['31/04/2026']), isNull);
      expect(find(['30/02/2026']), isNull);
      expect(find(['31/31/2026']), isNull);
      expect(find(['29/02/2026']), isNull, reason: '2026 is not a leap year');
    });

    test('a leap day in a leap year', () {
      expect(find(['29/02/2024']), DateTime(2024, 2, 29));
    });

    test('a date in the future', () {
      expect(find(['25/12/2026']), isNull);
      expect(find(['19/11/2026']), isNull);
      expect(find(['2027-01-01']), isNull);
    });

    test('today is fine', () {
      expect(find(['18/11/2026']), DateTime(2026, 11, 18));
    });

    test('a year before 2000', () {
      expect(find(['16/11/1999']), isNull);
    });

    test('a time alone is not a date', () {
      expect(find(['14:35', '08:12:45']), isNull);
    });
  });

  group('choosing among lines', () {
    test('takes the first valid date from the top', () {
      expect(find(['16/11/2026', '01/01/2026']), DateTime(2026, 11, 16));
    });

    test('skips a future date such as an expiry and finds the real one', () {
      expect(
        find(['Valid until 12/12/2030', 'Date 16/11/2026']),
        DateTime(2026, 11, 16),
      );
    });

    test('is null when there is no date or no text', () {
      expect(find(['TOTAL 10.00', 'THANK YOU']), isNull);
      expect(find([]), isNull);
    });
  });
}
