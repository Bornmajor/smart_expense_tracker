import 'package:equatable/equatable.dart';

import '../../domain/entities/category.dart';

sealed class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => [];
}

final class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();
}

final class CategoriesLoaded extends CategoriesState {
  const CategoriesLoaded(this.categories);

  final List<Category> categories;

  @override
  List<Object?> get props => [categories];
}

final class CategoriesError extends CategoriesState {
  const CategoriesError();
}
