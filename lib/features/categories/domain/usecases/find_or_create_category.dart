import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';
import '../validation/category_rules.dart';

/// Gives back the category with this name, creating it when there is none.
///
/// Used where the user adds a category on the way to something else, such as
/// while filling in an expense. Typing a name they already have is not a
/// mistake there, so it quietly picks the existing category. (The Categories
/// screen uses [CreateCategory], which reports a duplicate instead.)
class FindOrCreateCategory {
  FindOrCreateCategory(this._repository, {String Function()? newId})
    : _newId = newId ?? (() => const Uuid().v4());

  final CategoryRepository _repository;
  final String Function() _newId;

  Future<Result<Category>> call(String name) async {
    try {
      final existing = await _repository.getAll();

      final found = CategoryRules.findByName(name, existing);
      if (found != null) return Success(found);

      final error = CategoryRules.validateName(name, existing);
      if (error != null) {
        return Failure(ValidationFailure({CategoryField.name: error}));
      }

      final category = Category(
        id: _newId(),
        name: CategoryRules.cleanName(name),
      );
      await _repository.save(category);
      return Success(category);
    } on StorageException {
      return const Failure(StorageFailure());
    }
  }
}
