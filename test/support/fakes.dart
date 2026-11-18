import 'dart:async';

import 'package:smart_expense_tracker/features/categories/domain/entities/category.dart';
import 'package:smart_expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:smart_expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:smart_expense_tracker/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:smart_expense_tracker/features/security/domain/repositories/biometric_authenticator.dart';
import 'package:smart_expense_tracker/features/security/domain/repositories/security_repository.dart';
import 'package:smart_expense_tracker/features/settings/domain/entities/app_theme_mode.dart';
import 'package:smart_expense_tracker/features/settings/domain/repositories/settings_repository.dart';

class FakeExpenseRepository implements ExpenseRepository {
  FakeExpenseRepository({List<Expense> initial = const []})
    : saved = List.of(initial);

  final List<Expense> saved;

  /// When set, `save` throws it (to test failure handling).
  Object? saveError;

  /// When set, `delete` throws it.
  Object? deleteError;

  final _changes = StreamController<List<Expense>>.broadcast();

  @override
  Future<void> save(Expense expense) async {
    final error = saveError;
    if (error != null) throw error;
    // Same as the real repository: an existing id is replaced.
    final index = saved.indexWhere((e) => e.id == expense.id);
    if (index >= 0) {
      saved[index] = expense;
    } else {
      saved.add(expense);
    }
    _changes.add(List.of(saved));
  }

  @override
  Future<void> delete(String id) async {
    final error = deleteError;
    if (error != null) throw error;
    saved.removeWhere((e) => e.id == id);
    _changes.add(List.of(saved));
  }

  @override
  Stream<List<Expense>> watchAll() async* {
    yield List.of(saved);
    yield* _changes.stream;
  }
}

class FakeCategoryRepository implements CategoryRepository {
  FakeCategoryRepository([
    List<Category> initial = defaultCategories,
    Map<String, int> expenseCounts = const {},
  ]) : categories = List.of(initial),
       expenseCounts = Map.of(expenseCounts);

  static const defaultCategories = [
    Category(id: 'food', name: 'Food'),
    Category(id: 'transport', name: 'Transport'),
  ];

  /// Like the real database: includes the "Other" fallback category.
  static const withFallback = [
    Category(id: 'food', name: 'Food'),
    Category(id: 'transport', name: 'Transport'),
    Category(id: Category.fallbackId, name: 'Other'),
  ];

  final List<Category> categories;

  /// Category id -> how many expenses use it.
  final Map<String, int> expenseCounts;

  /// Every `deleteAndMoveExpenses` call, as (id, moveToId).
  final List<(String, String)> deletions = [];

  /// When set, the matching operation throws it.
  Object? saveError;
  Object? deleteError;
  Object? countError;

  final _changes = StreamController<List<Category>>.broadcast();

  @override
  Stream<List<Category>> watchAll() async* {
    yield List.of(categories);
    yield* _changes.stream;
  }

  @override
  Future<List<Category>> getAll() async => List.of(categories);

  @override
  Future<void> save(Category category) async {
    final error = saveError;
    if (error != null) throw error;
    final index = categories.indexWhere((c) => c.id == category.id);
    if (index >= 0) {
      categories[index] = category;
    } else {
      categories.add(category);
    }
    _changes.add(List.of(categories));
  }

  @override
  Future<int> countExpenses(String id) async {
    final error = countError;
    if (error != null) throw error;
    return expenseCounts[id] ?? 0;
  }

  @override
  Future<int> deleteAndMoveExpenses({
    required String id,
    required String moveToId,
  }) async {
    final error = deleteError;
    if (error != null) throw error;
    deletions.add((id, moveToId));
    categories.removeWhere((c) => c.id == id);
    final moved = expenseCounts.remove(id) ?? 0;
    expenseCounts[moveToId] = (expenseCounts[moveToId] ?? 0) + moved;
    _changes.add(List.of(categories));
    return moved;
  }
}

class ErrorExpenseRepository implements ExpenseRepository {
  @override
  Future<void> save(Expense expense) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Stream<List<Expense>> watchAll() => Stream.error(Exception('boom'));
}

class ErrorCategoryRepository implements CategoryRepository {
  @override
  Stream<List<Category>> watchAll() => Stream.error(Exception('boom'));

  @override
  Future<List<Category>> getAll() async => const [];

  @override
  Future<void> save(Category category) async {}

  @override
  Future<int> countExpenses(String id) async => 0;

  @override
  Future<int> deleteAndMoveExpenses({
    required String id,
    required String moveToId,
  }) async => 0;
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({this.mode = AppThemeMode.system});

  AppThemeMode mode;

  @override
  AppThemeMode get themeMode => mode;

  @override
  Future<void> setThemeMode(AppThemeMode value) async => mode = value;
}

class FakeSecurityRepository implements SecurityRepository {
  FakeSecurityRepository({this.enabled = false});

  bool enabled;

  @override
  bool get isBiometricEnabled => enabled;

  @override
  Future<void> setBiometricEnabled(bool value) async => enabled = value;
}

class FakeBiometricAuthenticator implements BiometricAuthenticator {
  FakeBiometricAuthenticator({this.available = true, this.succeeds = true});

  bool available;
  bool succeeds;
  int authenticateCalls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate({required String reason}) async {
    authenticateCalls++;
    return succeeds;
  }
}

class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository({this._completed = false});

  bool _completed;

  @override
  bool get isCompleted => _completed;

  @override
  Future<void> complete() async => _completed = true;
}
