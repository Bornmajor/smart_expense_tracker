import 'package:uuid/uuid.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';
import '../validation/category_rules.dart';

/// Validates a new category name and saves the category.
class CreateCategory {
  CreateCategory(this._repository, {String Function()? newId})
    : _newId = newId ?? (() => const Uuid().v4());

  final CategoryRepository _repository;
  final String Function() _newId;

  Future<Result<Category>> call(String name) async {
    try {
      final error = CategoryRules.validateName(
        name,
        await _repository.getAll(),
      );
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
