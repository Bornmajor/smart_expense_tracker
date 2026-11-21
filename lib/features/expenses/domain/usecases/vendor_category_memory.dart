import '../../../../core/errors/storage_exception.dart';
import '../entities/expense.dart';
import '../repositories/expense_repository.dart';
import '../validation/expense_rules.dart';

/// Remembers which category the user puts each vendor in, so the next expense
/// from that vendor starts with the same category.
///
/// It learns from the expenses already saved, so there is nothing extra to
/// store and nothing to teach it: correcting a category once is enough. It
/// only suggests; the user can always pick another.
class VendorCategoryMemory {
  const VendorCategoryMemory(this._expenses);

  final ExpenseRepository _expenses;

  /// Lowercase, trimmed, with runs of spaces made one, so "CORNER  Cafe " and
  /// "Corner Cafe" are the same vendor.
  static String normalize(String vendor) =>
      vendor.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  /// The category used most for [vendor], or null when there is no history.
  /// When two categories are used equally often, the one used most recently
  /// wins. With [availableIds], only those categories can be returned.
  Future<String?> categoryFor(
    String? vendor, {
    Set<String>? availableIds,
  }) async {
    final key = normalize(vendor ?? '');
    if (key.isEmpty || key == normalize(ExpenseRules.unknownVendor)) {
      return null;
    }

    final List<Expense> expenses;
    try {
      expenses = await _expenses.watchAll().first;
    } on StorageException {
      return null;
    }

    final counts = <String, int>{};
    final lastUsed = <String, DateTime>{};
    for (final expense in expenses) {
      if (normalize(expense.vendor) != key) continue;
      final id = expense.categoryId;
      if (availableIds != null && !availableIds.contains(id)) continue;

      counts.update(id, (n) => n + 1, ifAbsent: () => 1);
      final seen = lastUsed[id];
      if (seen == null || expense.date.isAfter(seen)) {
        lastUsed[id] = expense.date;
      }
    }
    if (counts.isEmpty) return null;

    return counts.keys.reduce((a, b) {
      final byCount = counts[a]!.compareTo(counts[b]!);
      if (byCount != 0) return byCount > 0 ? a : b;
      return lastUsed[a]!.isAfter(lastUsed[b]!) ? a : b;
    });
  }
}
