import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/database/app_database.dart';
import 'package:smart_expense_tracker/features/backup/data/repositories/backup_repository_impl.dart';

import 'backup_fakes.dart';

/// `docs/sample-backup-2026.json` is a file a person restores to see the trend
/// charts with data in them, so it has to stay a backup the app really accepts,
/// in the same shape the app writes itself.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('the sample backup restores, with three expenses a month', () async {
    final bytes = File('docs/sample-backup-2026.json').readAsBytesSync();
    final codec = testCodec();
    final repository = BackupRepositoryImpl(db);

    expect(codec.isEncrypted(bytes), isFalse);
    await repository.replaceAll(await codec.decode(bytes));

    final rows = await db.select(db.expenses).get();
    expect(rows, hasLength(33));
    for (var month = 1; month <= 11; month++) {
      expect(
        rows.where((r) => r.date.toUtc().month == month),
        hasLength(3),
        reason: 'month $month',
      );
    }
  });

  test('the sample has the same fields as a backup the app writes', () async {
    final repository = BackupRepositoryImpl(db);
    await db
        .into(db.expenses)
        .insert(
          ExpensesCompanion.insert(
            id: 'x',
            vendor: 'V',
            amountMinor: 100,
            date: DateTime(2026, 1, 1),
            categoryId: 'food',
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        );
    final written = jsonDecode(
      utf8.decode(await testCodec().encode(await repository.read())),
    ) as Map<String, dynamic>;
    final sample = jsonDecode(
      File('docs/sample-backup-2026.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    expect(sample.keys.toSet(), written.keys.toSet());
    for (final table in ['categories', 'expenses']) {
      expect(
        (sample[table] as List).first.keys.toSet(),
        (written[table] as List).first.keys.toSet(),
        reason: table,
      );
    }
  });
}
