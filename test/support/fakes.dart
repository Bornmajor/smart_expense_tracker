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
