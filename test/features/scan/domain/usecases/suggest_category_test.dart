import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/scan/domain/usecases/suggest_category.dart';

void main() {
  const suggest = SuggestCategory();
  const all = {'food', 'transport', 'bills', 'shopping', 'health', 'other'};

  String? run({
    String? vendor,
    List<String> lines = const [],
    Set<String> ids = all,
  }) => suggest(vendor: vendor, lines: lines, availableIds: ids);

  group('SuggestCategory from the vendor', () {
    test('a supermarket is food', () {
      expect(run(vendor: 'Naivas Supermarket'), 'food');
    });

    test('a coffee shop is food', () {
      expect(run(vendor: 'Java Coffee House'), 'food');
    });

    test('a petrol station is transport', () {
      expect(run(vendor: 'Shell Petrol Station'), 'transport');
    });

    test('a ride service is transport', () {
      expect(run(vendor: 'Uber'), 'transport');
    });

    test('a pharmacy is health', () {
      expect(run(vendor: 'City Pharmacy'), 'health');
    });

    test('a clothing shop is shopping', () {
      expect(run(vendor: 'Urban Fashion Boutique'), 'shopping');
    });

    test('an electricity bill is bills', () {
      expect(run(vendor: 'Electricity Prepaid Token'), 'bills');
    });

    test('ignores case', () {
      expect(run(vendor: 'CITY PHARMACY'), 'health');
    });
  });

  group('SuggestCategory from the items', () {
    test('uses words on the receipt when the vendor says nothing', () {
      expect(
        run(vendor: 'Waiyaki Way 7', lines: ['UNLEADED 30.00 L', 'DIESEL']),
        'transport',
      );
    });

    test('works with no vendor at all', () {
      expect(run(lines: ['PHARMACY', 'PANADOL 150.00']), 'health');
    });

    test('the vendor outweighs words among the items', () {
      expect(
        run(vendor: 'City Pharmacy', lines: ['COFFEE VOUCHER 50.00']),
        'health',
      );
    });
  });

  group('SuggestCategory stays quiet when unsure', () {
    test('returns null when nothing matches', () {
      expect(run(vendor: 'Zyx Ltd', lines: ['ITEM 10.00']), isNull);
      expect(run(), isNull);
    });

    test('returns null on an exact tie', () {
      // "bar" is food, "hardware" is shopping, each worth the same.
      expect(run(vendor: 'Bar Hardware'), isNull);
    });

    test('matches whole words only', () {
      expect(run(vendor: 'Bolton Street Barcode Systems'), isNull);
    });

    test('never suggests the Other category', () {
      expect(run(vendor: 'Misc Other Things', lines: ['other']), isNull);
    });
  });

  group('SuggestCategory only suggests categories the user has', () {
    test('skips a category that no longer exists', () {
      expect(
        run(vendor: 'Naivas Supermarket', ids: {'transport', 'other'}),
        isNull,
      );
    });

    test('still finds one of the categories that remain', () {
      expect(
        run(vendor: 'Naivas Supermarket Pharmacy', ids: {'health', 'other'}),
        'health',
      );
    });

    test('suggests nothing when no ids are available', () {
      expect(run(vendor: 'City Pharmacy', ids: {}), isNull);
    });
  });
}
