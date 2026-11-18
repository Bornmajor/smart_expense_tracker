import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/result.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/categories/domain/entities/category.dart';
import 'package:smart_expense_tracker/features/categories/domain/usecases/find_or_create_category.dart';
import 'package:smart_expense_tracker/features/categories/domain/validation/category_rules.dart';

import '../../../../support/fakes.dart';

void main() {
  late FakeCategoryRepository repository;
  late FindOrCreateCategory findOrCreate;

  Map<String, String> validationErrors(Result<Category> result) {
    final failure = (result as Failure<Category>).failure;
    return (failure as ValidationFailure).fieldErrors;
  }

  setUp(() {
    repository = FakeCategoryRepository(FakeCategoryRepository.withFallback);
    findOrCreate = FindOrCreateCategory(repository, newId: () => 'new-id');
  });

  group('FindOrCreateCategory', () {
    test('creates a category when the name is new', () async {
      final result = await findOrCreate('  Pets ');

      final category = (result as Success<Category>).value;
      expect(category, const Category(id: 'new-id', name: 'Pets'));
      expect(repository.categories, contains(category));
    });

    test(
      'returns the existing category for a name that is already used',
      () async {
        final result = await findOrCreate('food');

        expect(
          (result as Success<Category>).value,
          const Category(id: 'food', name: 'Food'),
        );
        expect(
          repository.categories,
          hasLength(3),
          reason: 'nothing was added',
        );
      },
    );

    test('matches ignoring case and the spaces around the name', () async {
      for (final name in ['FOOD', '  Food  ', 'fOoD']) {
        final result = await findOrCreate(name);

        expect(
          (result as Success<Category>).value.id,
          'food',
          reason: 'name: "$name"',
        );
      }
      expect(repository.categories, hasLength(3));
    });

    test('finds the fallback category by its current name', () async {
      final result = await findOrCreate('other');

      expect((result as Success<Category>).value.isFallback, isTrue);
    });

    test('rejects a blank name and saves nothing', () async {
      final result = await findOrCreate('   ');

      expect(validationErrors(result), {
        CategoryField.name: CategoryError.nameRequired,
      });
      expect(repository.categories, hasLength(3));
    });

    test('rejects a name that is too long', () async {
      final result = await findOrCreate('a' * 31);

      expect(validationErrors(result), {
        CategoryField.name: CategoryError.nameTooLong,
      });
    });

    test('returns a storage failure when saving fails', () async {
      repository.saveError = const StorageException('disk full');

      final result = await findOrCreate('Pets');

      expect((result as Failure<Category>).failure, const StorageFailure());
    });

    test('does not need to save anything for an existing name', () async {
      repository.saveError = const StorageException('disk full');

      final result = await findOrCreate('Food');

      expect(result, isA<Success<Category>>());
    });

    test('generates a different id each time by default', () async {
      final useCase = FindOrCreateCategory(repository);

      final first = await useCase('Pets');
      final second = await useCase('Gifts');

      expect(
        (first as Success<Category>).value.id,
        isNot((second as Success<Category>).value.id),
      );
    });
  });
}
