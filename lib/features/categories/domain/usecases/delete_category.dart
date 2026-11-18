import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';
import '../validation/category_rules.dart';

/// Deletes a category. Its expenses move to the fallback category ("Other")
/// first, so no expense is ever left without a category.
class DeleteCategory {
  DeleteCategory(this._repository);

  final CategoryRepository _repository;

  /// On success, the value is how many expenses were moved.
  Future<Result<int>> call(Category category) async {
    if (category.isFallback) {
      return const Failure(
        ValidationFailure({
          CategoryField.name: CategoryError.cannotDeleteFallback,
        }),
      );
    }

    try {
      final moved = await _repository.deleteAndMoveExpenses(
        id: category.id,
        moveToId: Category.fallbackId,
      );
      return Success(moved);
    } on StorageException {
      return const Failure(StorageFailure());
    }
  }
}
