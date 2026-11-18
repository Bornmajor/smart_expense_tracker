import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';
import '../validation/category_rules.dart';

/// Validates a new name for a category and saves it. The id stays the same,
/// so every expense keeps its category.
class RenameCategory {
  RenameCategory(this._repository);

  final CategoryRepository _repository;

  Future<Result<Category>> call(Category original, String name) async {
    try {
      final error = CategoryRules.validateName(
        name,
        await _repository.getAll(),
        exceptId: original.id,
      );
      if (error != null) {
        return Failure(ValidationFailure({CategoryField.name: error}));
      }

      final renamed = Category(
        id: original.id,
        name: CategoryRules.cleanName(name),
      );
      await _repository.save(renamed);
      return Success(renamed);
    } on StorageException {
      return const Failure(StorageFailure());
    }
  }
}
