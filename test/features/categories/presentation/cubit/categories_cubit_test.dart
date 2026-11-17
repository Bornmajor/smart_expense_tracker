import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:smart_expense_tracker/features/categories/presentation/cubit/categories_state.dart';

import '../../../../support/fakes.dart';

void main() {
  group('CategoriesCubit', () {
    blocTest<CategoriesCubit, CategoriesState>(
      'emits the categories from the repository',
      build: () => CategoriesCubit(FakeCategoryRepository()),
      expect: () => const [
        CategoriesLoaded(FakeCategoryRepository.defaultCategories),
      ],
    );

    blocTest<CategoriesCubit, CategoriesState>(
      'emits an error state when the stream fails',
      build: () => CategoriesCubit(ErrorCategoryRepository()),
      expect: () => const [CategoriesError()],
    );
  });
}
