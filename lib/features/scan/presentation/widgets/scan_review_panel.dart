import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../domain/entities/scan_result.dart';
import '../scan_messages.dart';
import 'receipt_viewer.dart';

/// Shown above the expense form after a scan: the receipt photo, so the user
/// can compare it with the filled-in fields, and notes on what to check.
/// Tapping the photo opens it large, where it can be zoomed.
class ScanReviewPanel extends StatelessWidget {
  const ScanReviewPanel({super.key, required this.scan});

  final ScanResult scan;

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
                onTap: () => showReceiptViewer(context, scan.photoPath),
                child: ClipRRect(
                  borderRadius: AppRadius.mdAll,
                  child: SizedBox(
                    width: 72,
                    height: 96,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(
                          File(scan.photoPath),
                          fit: BoxFit.cover,
                          // A small copy is enough for the thumbnail.
                          cacheWidth: 216,
                          errorBuilder: (_, _, _) => ColoredBox(
                            color: context.scheme.surfaceContainerHighest,
                            child: const Icon(Icons.receipt_long_outlined),
                          ),
                        ),
                        // Says the picture can be opened.
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            margin: const EdgeInsets.all(AppSpacing.xs),
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.zoom_out_map,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
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
                  Text(
                    'Tap the photo to enlarge it.',
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
