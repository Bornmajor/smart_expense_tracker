import 'dart:async';

import 'package:smart_expense_tracker/features/categories/domain/entities/category.dart';
import 'package:smart_expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:smart_expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:smart_expense_tracker/features/onboarding/domain/repositories/onboarding_repository.dart';

class FakeExpenseRepository implements ExpenseRepository {
  FakeExpenseRepository({List<Expense> initial = const []})
    : saved = List.of(initial);

  final List<Expense> saved;

  /// When set, `save` throws it (to test failure handling).
  Object? saveError;

  final _changes = StreamController<List<Expense>>.broadcast();

  @override
  Future<void> save(Expense expense) async {
    final error = saveError;
    if (error != null) throw error;
    saved.add(expense);
    _changes.add(List.of(saved));
  }

  @override
  Stream<List<Expense>> watchAll() async* {
    yield List.of(saved);
    yield* _changes.stream;
  }
}

class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository([this.categories = defaultCategories]);

  static const defaultCategories = [
    Category(id: 'food', name: 'Food'),
    Category(id: 'transport', name: 'Transport'),
  ];

  final List<Category> categories;

  @override
  Stream<List<Category>> watchAll() => Stream.value(categories);
}

class ErrorExpenseRepository implements ExpenseRepository {
  @override
  Future<void> save(Expense expense) async {}

  @override
  Stream<List<Expense>> watchAll() => Stream.error(Exception('boom'));
}

class ErrorCategoryRepository implements CategoryRepository {
  @override
  Stream<List<Category>> watchAll() => Stream.error(Exception('boom'));
}

class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository({this._completed = false});

  bool _completed;

  @override
  bool get isCompleted => _completed;

  @override
  Future<void> complete() async => _completed = true;
}
