import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../../../core/utils/currency.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';
import '../entities/export_format.dart';
import '../export_exception.dart';
import '../repositories/report_sharer.dart';
import '../repositories/report_writer.dart';
import 'build_monthly_report.dart';

/// Makes the report for one month and opens the share sheet with it.
class ExportMonth {
  ExportMonth({
    required this._expenses,
    required this._categories,
    required this._pdf,
    required this._csv,
    required this._sharer,
    required this._currency,
    this._build = const BuildMonthlyReport(),
  });

  final ExpenseRepository _expenses;
  final CategoryRepository _categories;
  final ReportWriter _pdf;
  final ReportWriter _csv;
  final ReportSharer _sharer;

  /// The currency to write amounts in, read each time because the user can
  /// change it in Settings.
  final Currency Function() _currency;
  final BuildMonthlyReport _build;

  /// [month] is any day in the month to export.
  Future<Result<void>> call(DateTime month, ExportFormat format) async {
    try {
      final expenses = await _expenses.watchAll().first;
      final categories = await _categories.getAll();

      final report = _build(expenses, categories, month, currency: _currency());
      if (report.rows.isEmpty) {
        return const Failure(ExportFailure(ExportProblem.nothingToExport));
      }

      final writer = switch (format) {
        ExportFormat.pdf => _pdf,
        ExportFormat.csv => _csv,
      };
      await _sharer.share(await writer.write(report));
      return const Success(null);
    } on StorageException {
      return const Failure(StorageFailure());
    } on ExportException catch (e) {
      return Failure(ExportFailure(e.problem));
    }
  }
}
