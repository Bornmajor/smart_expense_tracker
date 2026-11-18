import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/usecases/create_category.dart';
import '../../domain/usecases/delete_category.dart';
import '../../domain/usecases/find_or_create_category.dart';
import '../../domain/usecases/rename_category.dart';

class CategoryActionsState extends Equatable {
  const CategoryActionsState({this.busy = false});

  /// True while an action runs, so the screen can ignore further taps.
  final bool busy;

  @override
  List<Object?> get props => [busy];
}

/// The things a user can do with categories. Each action returns its result
/// so the screen that asked (a sheet, a dialog) can show the outcome itself.
/// An action started while another one runs is ignored and returns null.
class CategoryActionsCubit extends Cubit<CategoryActionsState> {
  CategoryActionsCubit({
    required this._createCategory,
    required this._findOrCreateCategory,
    required this._renameCategory,
    required this._deleteCategory,
    required this._repository,
  }) : super(const CategoryActionsState());

  final CreateCategory _createCategory;
  final FindOrCreateCategory _findOrCreateCategory;
  final RenameCategory _renameCategory;
  final DeleteCategory _deleteCategory;
  final CategoryRepository _repository;

  Future<Result<Category>?> create(String name) =>
      _run(() => _createCategory(name));

  /// The category with this name, created if it does not exist yet. A name the
  /// user already has returns that category instead of an error.
  Future<Result<Category>?> findOrCreate(String name) =>
      _run(() => _findOrCreateCategory(name));

  Future<Result<Category>?> rename(Category category, String name) =>
      _run(() => _renameCategory(category, name));

  /// On success the value is how many expenses moved to the fallback category.
  Future<Result<int>?> delete(Category category) =>
      _run(() => _deleteCategory(category));

  /// How many expenses use the category, for the delete confirmation.
  /// Reads as 0 if storage fails; the delete itself still reports a failure.
  Future<int> expenseCount(String categoryId) async {
    try {
      return await _repository.countExpenses(categoryId);
    } on StorageException {
      return 0;
    }
  }

  Future<Result<T>?> _run<T>(Future<Result<T>> Function() action) async {
    if (state.busy) return null;
    emit(const CategoryActionsState(busy: true));
    try {
      return await action();
    } finally {
      emit(const CategoryActionsState());
    }
  }
}
