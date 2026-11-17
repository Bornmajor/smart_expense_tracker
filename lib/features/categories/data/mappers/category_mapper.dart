import '../../../../core/database/app_database.dart';
import '../../domain/entities/category.dart';

extension CategoryRowMapper on CategoryRow {
  Category toEntity() => Category(id: id, name: name);
}
