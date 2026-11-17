import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/category_repository.dart';
import 'categories_state.dart';

class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit(CategoryRepository repository)
    : super(const CategoriesLoading()) {
    _subscription = repository.watchAll().listen(
      (categories) => emit(CategoriesLoaded(categories)),
      onError: (Object _) => emit(const CategoriesError()),
    );
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
