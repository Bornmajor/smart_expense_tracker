import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/result.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/categories/domain/entities/category.dart';
import 'package:smart_expense_tracker/features/categories/domain/usecases/create_category.dart';
import 'package:smart_expense_tracker/features/categories/domain/usecases/delete_category.dart';
import 'package:smart_expense_tracker/features/categories/domain/usecases/find_or_create_category.dart';
import 'package:smart_expense_tracker/features/categories/domain/usecases/rename_category.dart';
import 'package:smart_expense_tracker/features/categories/presentation/cubit/category_actions_cubit.dart';

import '../../../../support/fakes.dart';

void main() {
  const food = Category(id: 'food', name: 'Food');
  late FakeCategoryRepository repository;
  late CategoryActionsCubit cubit;

  setUp(() {
    repository = FakeCategoryRepository(FakeCategoryRepository.withFallback, {
      'food': 2,
    });
    cubit = CategoryActionsCubit(
      createCategory: CreateCategory(repository, newId: () => 'new-id'),
      findOrCreateCategory: FindOrCreateCategory(
        repository,
        newId: () => 'new-id',
      ),
      renameCategory: RenameCategory(repository),
      deleteCategory: DeleteCategory(repository),
      repository: repository,
    );
  });

  tearDown(() => cubit.close());

  group('CategoryActionsCubit', () {
    test('creates a category and returns it', () async {
      final result = await cubit.create('Pets');

      expect(
        (result! as Success<Category>).value,
        const Category(id: 'new-id', name: 'Pets'),
      );
    });

    test('finds an existing category, or creates a new one', () async {
      final existing = await cubit.findOrCreate('FOOD');
      expect((existing! as Success<Category>).value, food);

      final created = await cubit.findOrCreate('Pets');
      expect(
        (created! as Success<Category>).value,
        const Category(id: 'new-id', name: 'Pets'),
      );
    });

    test('renames a category', () async {
      final result = await cubit.rename(food, 'Groceries');

      expect((result! as Success<Category>).value.name, 'Groceries');
    });

    test('deletes a category and returns how many expenses moved', () async {
      final result = await cubit.delete(food);

      expect((result! as Success<int>).value, 2);
    });

    test('returns a failure instead of throwing when storage fails', () async {
      repository.saveError = const StorageException('disk full');

      final result = await cubit.create('Pets');

      expect((result! as Failure<Category>).failure, const StorageFailure());
    });

    test('is busy while an action runs, and idle before and after', () async {
      final states = <bool>[];
      final subscription = cubit.stream.listen((s) => states.add(s.busy));

      expect(cubit.state.busy, isFalse);
      await cubit.create('Pets');
      await pumpEventQueue();
      await subscription.cancel();

      expect(states, [true, false]);
    });

    test('ignores an action started while another one runs', () async {
      final first = cubit.create('Pets');
      final second = await cubit.create('Gifts');
      await first;

      expect(second, isNull);
      expect(repository.categories.map((c) => c.name), contains('Pets'));
      expect(
        repository.categories.map((c) => c.name),
        isNot(contains('Gifts')),
      );
    });

    test('goes back to idle even when an action throws', () async {
      final broken = CategoryActionsCubit(
        createCategory: _ThrowingCreate(repository),
        findOrCreateCategory: FindOrCreateCategory(repository),
        renameCategory: RenameCategory(repository),
        deleteCategory: DeleteCategory(repository),
        repository: repository,
      );

      await expectLater(broken.create('Pets'), throwsA(isA<StateError>()));

      expect(broken.state.busy, isFalse);
      await broken.close();
    });

    test('reports how many expenses use a category', () async {
      expect(await cubit.expenseCount('food'), 2);
      expect(await cubit.expenseCount('transport'), 0);
    });

    test('reads the count as zero when storage fails', () async {
      repository.countError = const StorageException('disk full');

      expect(await cubit.expenseCount('food'), 0);
    });
  });
}

class _ThrowingCreate extends CreateCategory {
  _ThrowingCreate(super.repository);

  @override
  Future<Result<Category>> call(String name) => throw StateError('bug');
}
