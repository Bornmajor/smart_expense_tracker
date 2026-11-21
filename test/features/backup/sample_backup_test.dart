import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/database/app_database.dart';

import 'backup_fakes.dart';

/// `docs/sample-backup-2026.json` is a file a person restores to see the trend
/// charts with data in them, so it has to stay a backup the app can open.
void main() {
  test('the sample backup opens and has three expenses a month', () async {
    final bytes = File('docs/sample-backup-2026.json').readAsBytesSync();
    final codec = testCodec();

    expect(codec.isEncrypted(bytes), isFalse);
    final data = await codec.decode(bytes);

    expect(data.expenses, hasLength(33));
    final rows = [for (final r in data.expenses) ExpenseRow.fromJson(r)];
    for (var month = 1; month <= 11; month++) {
      final inMonth = rows.where((r) => r.date.toUtc().month == month);
      expect(inMonth, hasLength(3), reason: 'month $month');
    }
    final categories = {for (final c in data.categories) c['id']};
    expect(rows.every((r) => categories.contains(r.categoryId)), isTrue);
  });
}
