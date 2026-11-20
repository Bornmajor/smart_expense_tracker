import 'dart:async';
import 'dart:typed_data';

import 'package:smart_expense_tracker/core/links/link_opener.dart';
import 'package:smart_expense_tracker/core/utils/currency.dart';
import 'package:smart_expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:smart_expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:smart_expense_tracker/features/categories/domain/entities/category.dart';
import 'package:smart_expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:smart_expense_tracker/features/export/domain/entities/monthly_report.dart';
import 'package:smart_expense_tracker/features/export/domain/entities/report_file.dart';
import 'package:smart_expense_tracker/features/export/domain/repositories/report_sharer.dart';
import 'package:smart_expense_tracker/features/export/domain/repositories/report_writer.dart';
import 'package:smart_expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:smart_expense_tracker/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/ocr_line.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/receipt_source.dart';
import 'package:smart_expense_tracker/features/scan/domain/repositories/receipt_photo_source.dart';
import 'package:smart_expense_tracker/features/scan/domain/repositories/receipt_text_reader.dart';
import 'package:smart_expense_tracker/features/scan/domain/scan_exception.dart';
import 'package:smart_expense_tracker/features/security/domain/entities/auth_outcome.dart';
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

/// A stand-in for the camera and gallery. Tell it what the user "chose", or
/// make it fail, and read back what it was asked to do.
class FakeReceiptPhotoSource implements ReceiptPhotoSource {
  FakeReceiptPhotoSource({this.path = '/tmp/receipt.jpg'});

  /// What the user chose. Null means they backed out.
  String? path;

  /// Photos for the next picks, one each time. When empty, [path] is used.
  /// Handy for a retake, which must return a different photo.
  final List<String> pathQueue = [];

  /// When set, `pick` throws it, as if the camera could not be used.
  ScanException? pickError;

  /// The photo waiting after Android restarted the app, or null for none.
  String? recoverPath;

  /// Every source `pick` was called with, in order.
  final List<ReceiptSource> picked = [];

  /// Every path passed to `discard`, in order.
  final List<String> discarded = [];

  /// How many times recovery was asked for.
  int recoverCalls = 0;

  @override
  Future<String?> pick(ReceiptSource source) async {
    picked.add(source);
    final error = pickError;
    if (error != null) throw error;
    return pathQueue.isNotEmpty ? pathQueue.removeAt(0) : path;
  }

  @override
  Future<String?> recoverLost() async {
    recoverCalls++;
    // A lost photo can be taken only once, like the real thing.
    final found = recoverPath;
    recoverPath = null;
    return found;
  }

  @override
  Future<void> discard(String path) async => discarded.add(path);
}

/// A stand-in for ML Kit: returns the lines it was given, or fails.
class FakeReceiptTextReader implements ReceiptTextReader {
  FakeReceiptTextReader([this.lines = const []]);

  List<OcrLine> lines;

  /// When set, `read` throws it. Use a `ScanException` for an expected problem
  /// or any other error for a bug.
  Object? error;

  /// Every photo path `read` was called with.
  final List<String> readPaths = [];

  @override
  Future<List<OcrLine>> read(String photoPath) async {
    readPaths.add(photoPath);
    final problem = error;
    if (problem != null) throw problem;
    return lines;
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
  FakeSettingsRepository({
    this.mode = AppThemeMode.system,
    this.selectedCurrency = Currency.none,
  });

  AppThemeMode mode;
  Currency selectedCurrency;

  @override
  AppThemeMode get themeMode => mode;

  @override
  Future<void> setThemeMode(AppThemeMode value) async => mode = value;

  @override
  Currency get currency => selectedCurrency;

  @override
  Future<void> setCurrency(Currency value) async => selectedCurrency = value;
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

  /// When set, `authenticate` ends this way, whatever [succeeds] says. Use it
  /// for the cases other than a plain pass or fail.
  AuthOutcome? outcome;
  int authenticateCalls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<AuthOutcome> authenticate({required String reason}) async {
    authenticateCalls++;
    return outcome ?? (succeeds ? AuthOutcome.success : AuthOutcome.failed);
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

/// Records what was shared instead of opening the share sheet.
class FakeReportSharer implements ReportSharer {
  final shared = <ReportFile>[];

  /// When set, `share` throws it.
  Object? error;

  /// When set, `share` waits for it, so a test can look at the screen while an
  /// export is still running.
  Future<void>? gate;

  @override
  Future<void> share(ReportFile file) async {
    await gate;
    final failure = error;
    if (failure != null) throw failure;
    shared.add(file);
  }
}

/// A writer that returns a small file, so use case tests do not need the real
/// PDF or CSV code.
class FakeReportWriter implements ReportWriter {
  FakeReportWriter(this.extension);

  final String extension;
  final reports = <MonthlyReport>[];

  @override
  Future<ReportFile> write(MonthlyReport report) async {
    reports.add(report);
    return ReportFile(
      name: report.fileName(extension),
      mimeType: 'x/$extension',
      bytes: Uint8List.fromList([1, 2, 3]),
    );
  }
}

/// Records the pages the app tried to open instead of launching a browser.
class FakeLinkOpener implements LinkOpener {
  FakeLinkOpener({this.succeeds = true});

  /// What `open` returns: false means no app could open the page.
  bool succeeds;
  final opened = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    opened.add(uri);
    return succeeds;
  }
}

class FakeBudgetRepository implements BudgetRepository {
  FakeBudgetRepository({List<Budget> initial = const []})
    : saved = List.of(initial);

  final List<Budget> saved;

  /// When set, `save` throws it.
  Object? saveError;

  /// When set, `delete` throws it.
  Object? deleteError;

  final _changes = StreamController<List<Budget>>.broadcast();

  @override
  Stream<List<Budget>> watchAll() async* {
    yield List.of(saved);
    yield* _changes.stream;
  }

  @override
  Future<void> save(Budget budget) async {
    final error = saveError;
    if (error != null) throw error;
    saved
      ..removeWhere((b) => b.scopeId == budget.scopeId)
      ..add(budget);
    _changes.add(List.of(saved));
  }

  @override
  Future<void> delete(String scopeId) async {
    final error = deleteError;
    if (error != null) throw error;
    saved.removeWhere((b) => b.scopeId == scopeId);
    _changes.add(List.of(saved));
  }
}
