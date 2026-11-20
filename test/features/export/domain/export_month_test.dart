import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/result.dart';
import 'package:smart_expense_tracker/core/errors/storage_exception.dart';
import 'package:smart_expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:smart_expense_tracker/features/export/domain/entities/export_format.dart';
import 'package:smart_expense_tracker/features/export/domain/export_exception.dart';
import 'package:smart_expense_tracker/features/export/domain/usecases/export_month.dart';

import '../../../support/builders.dart';
import '../../../support/fakes.dart';

void main() {
  late FakeExpenseRepository expenses;
  late FakeCategoryRepository categories;
  late FakeReportWriter pdf;
  late FakeReportWriter csv;
  late FakeReportSharer sharer;
  late ExportMonth export;
  final november = DateTime(2026, 11);

  setUp(() {
    expenses = FakeExpenseRepository(
      initial: [
        buildExpense(id: 'a', amountMinor: 1000),
        buildExpense(id: 'b', amountMinor: 250, date: DateTime(2026, 10, 3)),
      ],
    );
    categories = FakeCategoryRepository();
    pdf = FakeReportWriter('pdf');
    csv = FakeReportWriter('csv');
    sharer = FakeReportSharer();
    export = ExportMonth(
      expenses: expenses,
      categories: categories,
      pdf: pdf,
      csv: csv,
      sharer: sharer,
    );
  });

  test('shares a PDF made for the chosen month', () async {
    final result = await export(november, ExportFormat.pdf);

    expect(result, isA<Success<void>>());
    expect(sharer.shared.single.name, 'spendwise-iq-2026-11.pdf');
    expect(pdf.reports.single.totalMinor, 1000);
    expect(csv.reports, isEmpty);
  });

  test('shares a CSV when that is chosen', () async {
    await export(november, ExportFormat.csv);

    expect(sharer.shared.single.name, 'spendwise-iq-2026-11.csv');
    expect(csv.reports, hasLength(1));
    expect(pdf.reports, isEmpty);
  });

  test('only the chosen month goes into the report', () async {
    await export(DateTime(2026, 10), ExportFormat.csv);

    expect(csv.reports.single.rows, hasLength(1));
    expect(csv.reports.single.totalMinor, 250);
  });

  test('uses the category names from the repository', () async {
    await export(november, ExportFormat.csv);

    expect(csv.reports.single.rows.single.categoryName, 'Food');
  });

  test('a month with no expenses shares nothing', () async {
    final result = await export(DateTime(2025, 1), ExportFormat.pdf);

    expect(
      (result as Failure<void>).failure,
      const ExportFailure(ExportProblem.nothingToExport),
    );
    expect(sharer.shared, isEmpty);
    expect(pdf.reports, isEmpty);
  });

  test('reports when the share sheet cannot be opened', () async {
    sharer.error = const ExportException(ExportProblem.couldNotShare);

    final result = await export(november, ExportFormat.pdf);

    expect(
      (result as Failure<void>).failure,
      const ExportFailure(ExportProblem.couldNotShare),
    );
  });

  test('reports a storage failure when the expenses cannot be read', () async {
    final broken = ExportMonth(
      expenses: _ThrowingExpenses(),
      categories: categories,
      pdf: pdf,
      csv: csv,
      sharer: sharer,
    );

    final result = await broken(november, ExportFormat.pdf);

    expect((result as Failure<void>).failure, const StorageFailure());
  });

  test('a bug in the writer is not hidden', () async {
    sharer.error = StateError('bug');

    await expectLater(export(november, ExportFormat.pdf), throwsStateError);
  });
}

class _ThrowingExpenses extends FakeExpenseRepository {
  @override
  Stream<List<Expense>> watchAll() => Stream.error(const StorageException('x'));
}
