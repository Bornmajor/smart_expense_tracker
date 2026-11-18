import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/categories/domain/entities/category.dart';
import 'package:smart_expense_tracker/features/categories/domain/validation/category_rules.dart';

void main() {
  const existing = [
    Category(id: 'food', name: 'Food'),
    Category(id: 'transport', name: 'Transport'),
  ];

  group('CategoryRules.validateName', () {
    test('accepts a new, reasonable name', () {
      expect(CategoryRules.validateName('Pets', existing), isNull);
    });

    test('requires a name, ignoring spaces', () {
      for (final name in ['', '   ']) {
        expect(
          CategoryRules.validateName(name, existing),
          CategoryError.nameRequired,
          reason: 'name: "$name"',
        );
      }
    });

    test('allows the longest length and rejects one more', () {
      final longest = 'a' * CategoryRules.maxNameLength;

      expect(CategoryRules.validateName(longest, existing), isNull);
      expect(
        CategoryRules.validateName('${longest}a', existing),
        CategoryError.nameTooLong,
      );
    });

    test('does not count spaces around a long name', () {
      final padded = '  ${'a' * CategoryRules.maxNameLength}  ';

      expect(CategoryRules.validateName(padded, existing), isNull);
    });

    test('rejects a name another category has, ignoring case and spaces', () {
      for (final name in ['Food', 'food', '  FOOD  ']) {
        expect(
          CategoryRules.validateName(name, existing),
          CategoryError.nameTaken,
          reason: 'name: "$name"',
        );
      }
    });

    test('lets a category keep or re-case its own name', () {
      expect(
        CategoryRules.validateName('Food', existing, exceptId: 'food'),
        isNull,
      );
      expect(
        CategoryRules.validateName('FOOD', existing, exceptId: 'food'),
        isNull,
      );
    });

    test('still rejects another category\'s name when renaming', () {
      expect(
        CategoryRules.validateName('transport', existing, exceptId: 'food'),
        CategoryError.nameTaken,
      );
    });
  });

  group('Category', () {
    test('only the "other" category is the fallback', () {
      expect(const Category(id: 'other', name: 'Other').isFallback, isTrue);
      expect(const Category(id: 'food', name: 'Food').isFallback, isFalse);
    });

    test('stays the fallback when it is renamed', () {
      expect(const Category(id: 'other', name: 'Misc').isFallback, isTrue);
    });
  });
}
