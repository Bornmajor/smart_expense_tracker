import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/features/export/presentation/export_messages.dart';

void main() {
  final month = DateTime(2026, 11);

  test('names the month when there is nothing to export', () {
    expect(
      exportFailureMessage(
        const ExportFailure(ExportProblem.nothingToExport),
        month,
      ),
      'There are no expenses in November 2026 to export.',
    );
  });

  test('has a message for each export problem', () {
    final messages = {
      for (final p in ExportProblem.values)
        exportFailureMessage(ExportFailure(p), month),
    };

    expect(messages, hasLength(ExportProblem.values.length));
  });

  test('has a message for a storage failure', () {
    expect(
      exportFailureMessage(const StorageFailure(), month),
      contains('read your expenses'),
    );
  });

  test('has a general message for anything else', () {
    expect(
      exportFailureMessage(const AuthenticationFailure(), month),
      contains('export this month'),
    );
  });
}
