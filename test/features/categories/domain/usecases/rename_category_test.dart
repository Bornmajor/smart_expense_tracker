import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/result.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/categories/domain/entities/category.dart';
import 'package:smart_expense_tracker/features/categories/domain/usecases/rename_category.dart';
import 'package:smart_expense_tracker/features/categories/domain/validation/category_rules.dart';

import '../../../../support/fakes.dart';

void main() {
  const food = Category(id: 'food', name: 'Food');
  late FakeCategoryRepository repository;
  late RenameCategory renameCategory;

  Map<String, String> validationErrors(Result<Category> result) {
    final failure = (result as Failure<Category>).failure;
    return (failure as ValidationFailure).fieldErrors;
  }

  setUp(() {
    repository = FakeCategoryRepository(FakeCategoryRepository.withFallback);
    renameCategory = RenameCategory(repository);
  });

  group('RenameCategory', () {
    test('changes the name and keeps the id', () async {
      final result = await renameCategory(food, '  Groceries ');

      expect(
        (result as Success<Category>).value,
        const Category(id: 'food', name: 'Groceries'),
      );
      expect(repository.categories.map((c) => c.name), contains('Groceries'));
      expect(repository.categories.map((c) => c.name), isNot(contains('Food')));
    });

    test('lets a category change only the case of its own name', () async {
      final result = await renameCategory(food, 'FOOD');

      expect((result as Success<Category>).value.name, 'FOOD');
    });

    test('rejects a name another category has', () async {
      final result = await renameCategory(food, 'transport');

      expect(validationErrors(result), {
        CategoryField.name: CategoryError.nameTaken,
      });
      expect(repository.categories, contains(food));
    });

    test('rejects a blank name', () async {
      final result = await renameCategory(food, '  ');

      expect(validationErrors(result), {
        CategoryField.name: CategoryError.nameRequired,
      });
    });

    test('can rename the fallback category', () async {
      final result = await renameCategory(
        const Category(id: Category.fallbackId, name: 'Other'),
        'Misc',
      );

      expect((result as Success<Category>).value.isFallback, isTrue);
    });

    test('returns a storage failure when saving fails', () async {
      repository.saveError = const StorageException('disk full');

      final result = await renameCategory(food, 'Groceries');

      expect((result as Failure<Category>).failure, const StorageFailure());
    });
  });
}
