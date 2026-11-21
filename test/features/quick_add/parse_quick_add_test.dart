import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/quick_add/domain/entities/quick_add_draft.dart';
import 'package:smart_expense_tracker/features/quick_add/domain/usecases/parse_quick_add.dart';

void main() {
  // Saturday 21 November 2026.
  final parse = ParseQuickAdd(now: () => DateTime(2026, 11, 21, 14, 30));

  QuickAddDraft draft({
    int? amountMinor,
    DateTime? date,
    String vendor = '',
    String title = '',
  }) => QuickAddDraft(
    amountMinor: amountMinor,
    date: date,
    vendor: vendor,
    title: title,
  );

  group('the amount', () {
    test('a plain number', () {
      expect(parse('lunch 350').amountMinor, 35000);
    });

    test('with thousands commas and cents', () {
      expect(parse('rent 45,000').amountMinor, 4500000);
      expect(parse('coffee 12.50').amountMinor, 1250);
      expect(parse('12,5 coffee').amountMinor, isNull);
    });

    test('with k for thousands', () {
      expect(parse('laptop bag 2k').amountMinor, 200000);
      expect(parse('Java House 1.5k').amountMinor, 150000);
    });

    test('with a currency word or sign around it', () {
      expect(parse('ksh 1,200 airtel').amountMinor, 120000);
      expect(parse('airtime 100/=').amountMinor, 10000);
      expect(parse('kes500 snacks').amountMinor, 50000);
      expect(parse(r'books $20').amountMinor, 2000);
    });

    test('one with a marker beats a bigger one without', () {
      expect(parse('3 tickets ksh 1500').amountMinor, 150000);
    });

    test('otherwise the biggest number is the price', () {
      final result = parse('2 coffees 500');

      expect(result.amountMinor, 50000);
      expect(result.title, '2 coffees');
    });

    test('is missing when there is no number', () {
      expect(parse('lunch at java').amountMinor, isNull);
      expect(parse('lunch 0').amountMinor, isNull);
    });
  });

  group('the date', () {
    test('today, yesterday and the day before', () {
      expect(parse('tea 30 today').date, DateTime(2026, 11, 21));
      expect(parse('tea 30 yesterday').date, DateTime(2026, 11, 20));
      expect(parse('tea 30 day before yesterday').date, DateTime(2026, 11, 19));
    });

    test('in Swahili too', () {
      expect(parse('chai 30 leo').date, DateTime(2026, 11, 21));
      expect(parse('chai 30 jana').date, DateTime(2026, 11, 20));
      expect(parse('chai 30 juzi').date, DateTime(2026, 11, 19));
    });

    test('a weekday is the most recent one, today included', () {
      expect(parse('fuel 3000 on monday').date, DateTime(2026, 11, 16));
      expect(parse('dinner 800 saturday').date, DateTime(2026, 11, 21));
      expect(parse('coffee 250 last fri').date, DateTime(2026, 11, 20));
      expect(parse('coffee 250 sunday').date, DateTime(2026, 11, 15));
    });

    test('a day and a month name', () {
      expect(parse('rent 45000 on 1 nov').date, DateTime(2026, 11, 1));
      expect(parse('rent 45000 nov 3').date, DateTime(2026, 11, 3));
      expect(parse('gift 500 12th November 2025').date, DateTime(2025, 11, 12));
    });

    test('day first when written with a slash', () {
      expect(parse('bus 70 12/11').date, DateTime(2026, 11, 12));
      expect(parse('bus 70 5/3/2026').date, DateTime(2026, 3, 5));
      expect(parse('bus 70 5-3-26').date, DateTime(2026, 3, 5));
    });

    test('a date that is still to come this year is last year', () {
      expect(parse('gift 500 20 dec').date, DateTime(2025, 12, 20));
    });

    test('a decimal amount is not mistaken for a date', () {
      final result = parse('coffee 1.5k');

      expect(result.date, isNull);
      expect(result.amountMinor, 150000);
    });

    test('an impossible date is ignored', () {
      expect(parse('lunch 100 31/2').date, isNull);
      expect(parse('lunch 100 35 nov').date, isNull);
    });

    test('is missing when the line names none', () {
      expect(parse('lunch 350').date, isNull);
    });

    test('is not taken as part of the amount', () {
      final result = parse('rent 12 nov 4500');

      expect(result.date, DateTime(2026, 11, 12));
      expect(result.amountMinor, 450000);
    });
  });

  group('the vendor and title', () {
    test('the vendor follows "at", the title is the rest', () {
      expect(
        parse('lunch 350 at java yesterday'),
        draft(
          amountMinor: 35000,
          date: DateTime(2026, 11, 20),
          vendor: 'Java',
          title: 'Lunch',
        ),
      );
    });

    test('"from" and "@" work too', () {
      expect(parse('milk 120 from Naivas').vendor, 'Naivas');
      expect(parse('milk 120 @ naivas').vendor, 'Naivas');
    });

    test('without "at", everything is the title', () {
      final result = parse('lunch 350 cafe yesterday');

      expect(result.vendor, '');
      expect(result.title, 'Lunch cafe');
    });

    test('keeps capitals the user typed', () {
      expect(parse('lunch 350 at KFC').vendor, 'KFC');
      expect(parse('lunch 350 at java house').vendor, 'Java House');
    });

    test('drops a leading "paid" or "spent"', () {
      expect(parse('paid 2500 for rent on 1 nov').title, 'Rent');
      expect(parse('spent 300 on snacks').title, 'Snacks');
    });

    test('puts the words after the vendor into the vendor name', () {
      expect(
        parse('bought milk 120 at Quick Mart Westlands').vendor,
        'Quick Mart Westlands',
      );
    });

    test('a date after the vendor does not stay in its name', () {
      final result = parse('lunch 350 at java house on monday');

      expect(result.vendor, 'Java House');
      expect(result.date, DateTime(2026, 11, 16));
    });
  });

  group('odd input', () {
    test('an empty or blank line finds nothing', () {
      expect(parse(''), const QuickAddDraft());
      expect(parse('   '), const QuickAddDraft());
    });

    test('words only keep the words as the title', () {
      expect(parse('hello there'), draft(title: 'Hello there'));
    });

    test('extra spaces and stray punctuation are tidied', () {
      expect(parse('  lunch,   350 ,  at  java  ').title, 'Lunch');
      expect(parse('  lunch,   350 ,  at  java  ').vendor, 'Java');
    });
  });
}
