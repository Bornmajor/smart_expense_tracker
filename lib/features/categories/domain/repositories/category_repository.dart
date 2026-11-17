import '../entities/category.dart';

abstract interface class CategoryRepository {
  /// Emits the full category list now and again whenever it changes.
  Stream<List<Category>> watchAll();
}
