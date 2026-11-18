import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../domain/entities/scan_result.dart';
import '../scan_messages.dart';

/// Shown above the expense form after a scan: the receipt photo, so the user
/// can compare it with the filled-in fields, and notes on what to check.
/// Tapping the photo opens it full screen, where it can be zoomed.
class ScanReviewPanel extends StatelessWidget {
  const ScanReviewPanel({super.key, required this.scan});

  final ScanResult scan;

  void _enlarge(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Stack(
          children: [
            InteractiveViewer(
              maxScale: 8,
              child: Center(
                child: Image.file(
                  File(scan.photoPath),
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = scanReviewNotes(scan);
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              label: 'Receipt photo, tap to enlarge',
              child: GestureDetector(
                onTap: () => _enlarge(context),
                child: ClipRRect(
                  borderRadius: AppRadius.mdAll,
                  child: SizedBox(
                    width: 72,
                    height: 96,
                    child: Image.file(
                      File(scan.photoPath),
                      fit: BoxFit.cover,
                      // A small copy is enough for the thumbnail.
                      cacheWidth: 216,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: context.scheme.surfaceContainerHighest,
                        child: const Icon(Icons.receipt_long_outlined),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Gap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Read from your receipt',
                    style: context.text.titleSmall,
                  ),
                  const Gap(AppSpacing.xs),
                  for (final note in notes) ...[
                    Text(note, style: context.text.bodySmall),
                    const Gap(AppSpacing.xs),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
