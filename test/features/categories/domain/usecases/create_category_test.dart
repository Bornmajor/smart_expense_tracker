import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/result.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/categories/domain/entities/category.dart';
import 'package:smart_expense_tracker/features/categories/domain/usecases/create_category.dart';
import 'package:smart_expense_tracker/features/categories/domain/validation/category_rules.dart';

import '../../../../support/fakes.dart';

void main() {
  late FakeCategoryRepository repository;
  late CreateCategory createCategory;

  Map<String, String> validationErrors(Result<Category> result) {
    final failure = (result as Failure<Category>).failure;
    return (failure as ValidationFailure).fieldErrors;
  }

  setUp(() {
    repository = FakeCategoryRepository(FakeCategoryRepository.withFallback);
    createCategory = CreateCategory(repository, newId: () => 'new-id');
  });

  group('CreateCategory', () {
    test('saves a trimmed name under a new id', () async {
      final result = await createCategory('  Pets  ');

      final category = (result as Success<Category>).value;
      expect(category, const Category(id: 'new-id', name: 'Pets'));
      expect(repository.categories, contains(category));
    });

    test('rejects a blank name and saves nothing', () async {
      final result = await createCategory('   ');

      expect(validationErrors(result), {
        CategoryField.name: CategoryError.nameRequired,
      });
      expect(repository.categories, hasLength(3));
    });

    test('rejects a name that is already used, ignoring case', () async {
      final result = await createCategory('FOOD');

      expect(validationErrors(result), {
        CategoryField.name: CategoryError.nameTaken,
      });
      expect(repository.categories, hasLength(3));
    });

    test('rejects a name that is too long', () async {
      final result = await createCategory('a' * 31);

      expect(validationErrors(result), {
        CategoryField.name: CategoryError.nameTooLong,
      });
    });

    test('returns a storage failure when saving fails', () async {
      repository.saveError = const StorageException('disk full');

      final result = await createCategory('Pets');

      expect((result as Failure<Category>).failure, const StorageFailure());
    });

    test('generates a different id each time by default', () async {
      final useCase = CreateCategory(repository);

      final first = await useCase('Pets');
      final second = await useCase('Gifts');

      expect(
        (first as Success<Category>).value.id,
        isNot((second as Success<Category>).value.id),
      );
    });
  });
}
