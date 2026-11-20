import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../domain/entities/export_format.dart';

/// Bottom sheet asking which kind of report to make for [month].
/// Returns null when the user closes it without choosing.
Future<ExportFormat?> showExportSheet(BuildContext context, DateTime month) {
  return showModalBottomSheet<ExportFormat>(
    context: context,
    // The Summary tab has its own navigator, which sits under the app's
    // floating button and tab bar. The root navigator puts the sheet above
    // them, so they cannot draw over it.
    useRootNavigator: true,
    builder: (context) => _ExportSheet(month: month),
  );
}

class _ExportSheet extends StatelessWidget {
  const _ExportSheet({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    // Scrolls when it does not fit, such as on a small phone with large text.
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Text(
                'Export ${DateFormat.yMMMM().format(month)}',
                style: context.text.titleLarge,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('PDF report'),
              subtitle: const Text('A clear summary to read, print or send'),
              onTap: () => Navigator.pop(context, ExportFormat.pdf),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('CSV spreadsheet'),
              subtitle: const Text('Every expense, to open in Excel or Sheets'),
              onTap: () => Navigator.pop(context, ExportFormat.csv),
            ),
          ],
        ),
      ),
    );
  }
}
