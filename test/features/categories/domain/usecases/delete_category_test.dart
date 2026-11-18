import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/result.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/categories/domain/entities/category.dart';
import 'package:smart_expense_tracker/features/categories/domain/usecases/delete_category.dart';
import 'package:smart_expense_tracker/features/categories/domain/validation/category_rules.dart';

import '../../../../support/fakes.dart';

void main() {
  const food = Category(id: 'food', name: 'Food');
  late FakeCategoryRepository repository;
  late DeleteCategory deleteCategory;

  setUp(() {
    repository = FakeCategoryRepository(FakeCategoryRepository.withFallback, {
      'food': 3,
    });
    deleteCategory = DeleteCategory(repository);
  });

  group('DeleteCategory', () {
    test('moves the expenses to Other and reports how many moved', () async {
      final result = await deleteCategory(food);

      expect((result as Success<int>).value, 3);
      expect(repository.deletions, [('food', Category.fallbackId)]);
      expect(repository.categories, isNot(contains(food)));
      expect(repository.expenseCounts[Category.fallbackId], 3);
    });

    test('reports zero when no expense used the category', () async {
      final result = await deleteCategory(
        const Category(id: 'transport', name: 'Transport'),
      );

      expect((result as Success<int>).value, 0);
    });

    test('refuses to delete the fallback category', () async {
      final result = await deleteCategory(
        const Category(id: Category.fallbackId, name: 'Other'),
      );

      final failure = (result as Failure<int>).failure as ValidationFailure;
      expect(failure.fieldErrors, {
        CategoryField.name: CategoryError.cannotDeleteFallback,
      });
      expect(repository.deletions, isEmpty);
    });

    test('refuses to delete the fallback even after it is renamed', () async {
      final result = await deleteCategory(
        const Category(id: Category.fallbackId, name: 'Misc'),
      );

      expect(result, isA<Failure<int>>());
      expect(repository.deletions, isEmpty);
    });

    test('returns a storage failure when storage fails', () async {
      repository.deleteError = const StorageException('disk full');

      final result = await deleteCategory(food);

      expect((result as Failure<int>).failure, const StorageFailure());
      expect(repository.categories, contains(food));
    });
  });
}
