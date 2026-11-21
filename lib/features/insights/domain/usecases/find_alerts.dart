import '../../../expenses/domain/entities/expense.dart';
import '../../../expenses/domain/validation/expense_rules.dart';
import '../entities/insight_alert.dart';

/// Looks through the expenses for things worth a second look. Plain rules on
/// the phone, nothing is sent anywhere.
class FindAlerts {
  const FindAlerts();

  /// How far back a duplicate or a large expense is still news.
  static const freshDays = 7;

  /// A charge this many times the usual one in its category is unusual.
  static const largeFactor = 3;

  /// Needed before "usual" means anything.
  static const minHistory = 5;
  static const historyDays = 90;

  /// A category this many times its average month is above normal.
  static const aboveNormalPercent = 150;

  /// Too small to be worth a message, in minor units (100.00).
  static const floorMinor = 10000;

  /// How many months in a row, at the same amount, make something look like a
  /// subscription before a change in its price is news.
  static const steadyMonths = 3;

  /// A price change has to be at least this much to be told (10.00)...
  static const priceFloorMinor = 1000;

  /// ...and at least this share of the old price.
  static const pricePercent = 5;

  /// How long after the new price first shows up it is still news.
  static const priceFreshDays = 35;

  static const maxAlerts = 3;

  /// The alerts for [today], most pressing first, at most [maxAlerts].
  List<InsightAlert> call(List<Expense> expenses, DateTime today) {
    final day = ExpenseRules.dayOnly(today);
    return [
      ..._duplicates(expenses, day),
      ..._large(expenses, day),
      ..._priceChanges(expenses, day),
      ..._aboveNormal(expenses, day),
    ].take(maxAlerts).toList();
  }

  bool _fresh(Expense e, DateTime day) =>
      !e.date.isAfter(day) && day.difference(e.date).inDays < freshDays;

  List<InsightAlert> _duplicates(List<Expense> expenses, DateTime day) {
    final recent = [
      for (final e in expenses)
        if (_fresh(e, day)) e,
    ]..sort((a, b) => a.date.compareTo(b.date));
    final found = <InsightAlert>[];
    final flagged = <String>{};

    for (var i = 0; i < recent.length; i++) {
      final a = recent[i];
      if (a.vendor == ExpenseRules.unknownVendor) continue;
      for (var j = i + 1; j < recent.length; j++) {
        final b = recent[j];
        if (b.date.difference(a.date).inDays > 1) break;
        final same =
            a.amountMinor == b.amountMinor &&
            a.vendor.trim().toLowerCase() == b.vendor.trim().toLowerCase();
        // A bill that repeats on purpose is not a mistake.
        final repeats = a.recurringRuleId != null || b.recurringRuleId != null;
        if (same && !repeats && flagged.add(b.id)) {
          found.add(
            InsightAlert(
              id: 'dup:${b.id}',
              kind: AlertKind.possibleDuplicate,
              categoryId: b.categoryId,
              amountMinor: b.amountMinor,
              vendor: b.vendor,
            ),
          );
        }
      }
    }
    return found;
  }

  List<InsightAlert> _large(List<Expense> expenses, DateTime day) {
    final since = day.subtract(const Duration(days: historyDays));
    final found = <InsightAlert>[];

    for (final e in expenses) {
      if (!_fresh(e, day) || e.amountMinor < floorMinor) continue;
      final history = [
        for (final o in expenses)
          if (o.id != e.id &&
              o.categoryId == e.categoryId &&
              !o.date.isBefore(since) &&
              !o.date.isAfter(e.date))
            o.amountMinor,
      ];
      if (history.length < minHistory) continue;
      final usual = _median(history);
      if (e.amountMinor >= usual * largeFactor) {
        found.add(
          InsightAlert(
            id: 'big:${e.id}',
            kind: AlertKind.unusuallyLarge,
            categoryId: e.categoryId,
            amountMinor: e.amountMinor,
            vendor: e.vendor,
            usualMinor: usual,
          ),
        );
      }
    }
    found.sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
    return found;
  }

  /// A vendor paid once a month, in [steadyMonths] months in a row at the same
  /// amount, and then once more in the next month at a different amount.
  List<InsightAlert> _priceChanges(List<Expense> expenses, DateTime day) {
    final byVendor = <String, List<Expense>>{};
    for (final e in expenses) {
      if (e.date.isAfter(day)) continue;
      final key = e.vendor.trim().toLowerCase();
      if (key.isEmpty || e.vendor == ExpenseRules.unknownVendor) continue;
      byVendor.putIfAbsent(key, () => []).add(e);
    }

    int monthIndex(Expense e) => e.date.year * 12 + e.date.month;

    final found = <InsightAlert>[];
    byVendor.forEach((key, list) {
      if (list.length < steadyMonths + 1) return;
      list.sort((a, b) => a.date.compareTo(b.date));
      final recent = list.sublist(list.length - (steadyMonths + 1));

      // One a month, in months that follow each other. Several in a month is a
      // shop visited often, not a subscription, in any of those months.
      for (var i = 1; i < recent.length; i++) {
        if (monthIndex(recent[i]) != monthIndex(recent[i - 1]) + 1) return;
      }
      final months = {for (final e in recent) monthIndex(e)};
      if (list.where((e) => months.contains(monthIndex(e))).length !=
          recent.length) {
        return;
      }

      final steady = recent.first.amountMinor;
      for (final e in recent.take(steadyMonths)) {
        if (e.amountMinor != steady) return;
      }

      final latest = recent.last;
      final change = (latest.amountMinor - steady).abs();
      if (change < priceFloorMinor || change * 100 < steady * pricePercent) {
        return;
      }
      if (day.difference(latest.date).inDays > priceFreshDays) return;

      found.add(
        InsightAlert(
          id: 'price:$key:${latest.date.year}-${latest.date.month}',
          kind: AlertKind.priceChanged,
          categoryId: latest.categoryId,
          amountMinor: latest.amountMinor,
          vendor: latest.vendor,
          usualMinor: steady,
        ),
      );
    });
    found.sort((a, b) {
      final byChange = (b.amountMinor - b.usualMinor!).abs().compareTo(
        (a.amountMinor - a.usualMinor!).abs(),
      );
      return byChange != 0 ? byChange : a.id.compareTo(b.id);
    });
    return found;
  }

  List<InsightAlert> _aboveNormal(List<Expense> expenses, DateTime day) {
    final month = DateTime(day.year, day.month);
    final totals = <String, Map<DateTime, int>>{};
    for (final e in expenses) {
      if (e.date.isAfter(day)) continue;
      final key = DateTime(e.date.year, e.date.month);
      final byMonth = totals.putIfAbsent(e.categoryId, () => {});
      byMonth[key] = (byMonth[key] ?? 0) + e.amountMinor;
    }

    final found = <InsightAlert>[];
    totals.forEach((categoryId, byMonth) {
      final thisMonth = byMonth[month] ?? 0;
      final before = [
        for (var back = 1; back <= 3; back++)
          byMonth[DateTime(month.year, month.month - back)] ?? 0,
      ];
      // Two months of habit are needed before "normal" means anything.
      if (before.where((total) => total > 0).length < 2) return;
      final average = before.reduce((a, b) => a + b) ~/ before.length;
      if (thisMonth * 100 >= average * aboveNormalPercent &&
          thisMonth - average >= floorMinor) {
        found.add(
          InsightAlert(
            id: 'cat:$categoryId:${month.year}-${month.month}',
            kind: AlertKind.categoryAboveNormal,
            categoryId: categoryId,
            amountMinor: thisMonth,
            usualMinor: average,
          ),
        );
      }
    });
    found.sort((a, b) => b.amountMinor.compareTo(a.amountMinor));
    return found;
  }

  int _median(List<int> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) ~/ 2;
  }
}
