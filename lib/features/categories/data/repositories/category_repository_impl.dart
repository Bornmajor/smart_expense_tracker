import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../mappers/category_mapper.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Category>> watchAll() {
    final query = _db.select(_db.categories)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch().map((rows) => rows.map((r) => r.toEntity()).toList());
  }
}
