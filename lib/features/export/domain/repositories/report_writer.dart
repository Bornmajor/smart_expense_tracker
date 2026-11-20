import '../entities/monthly_report.dart';
import '../entities/report_file.dart';

/// Turns a report into a file in one format (PDF or CSV).
abstract interface class ReportWriter {
  Future<ReportFile> write(MonthlyReport report);
}
