import '../entities/category.dart';

abstract interface class CategoryRepository {
  /// Emits the full category list now and again whenever it changes.
  Stream<List<Category>> watchAll();

  /// The current categories, once.
  Future<List<Category>> getAll();

  /// Adds the category, or renames it when the id already exists.
  /// Throws `StorageException` if storage fails.
  Future<void> save(Category category);

  /// How many expenses use the category.
  /// Throws `StorageException` if storage fails.
  Future<int> countExpenses(String id);

  /// Moves every expense of category [id] to [moveToId], then deletes the
  /// category, in one step: either both happen or neither does.
  /// Returns how many expenses were moved.
  /// Throws `StorageException` if storage fails.
  Future<int> deleteAndMoveExpenses({
    required String id,
    required String moveToId,
  });
}
