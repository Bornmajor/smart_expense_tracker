import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../scan/scan_features.dart';

enum AddExpenseChoice { manual, quickAdd, mpesa, scanCamera, scanFile }

/// Bottom sheet asking how the user wants to add an expense.
/// Manual entry is listed first because scanning is optional.
///
/// [cameraEnabled] is only for tests; the app follows [ScanFeatures].
Future<AddExpenseChoice?> showAddExpenseSheet(
  BuildContext context, {
  bool cameraEnabled = ScanFeatures.cameraEnabled,
}) {
  return showModalBottomSheet<AddExpenseChoice>(
    context: context,
    // With five choices the default height limit (just over half the screen)
    // would hide the last one behind a scroll. The sheet still scrolls on a
    // very small phone or at large text.
    isScrollControlled: true,
    builder: (context) => _AddExpenseSheet(cameraEnabled: cameraEnabled),
  );
}

class _AddExpenseSheet extends StatelessWidget {
  const _AddExpenseSheet({required this.cameraEnabled});

  final bool cameraEnabled;

  @override
  Widget build(BuildContext context) {
    // Scrolls when it does not fit, such as on a small phone with large text,
    // so a choice can never be cut off.
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Enter manually'),
              subtitle: const Text('Type in the details'),
              onTap: () => Navigator.pop(context, AddExpenseChoice.manual),
            ),
            ListTile(
              leading: const Icon(Icons.bolt),
              title: const Text('Type it in one line'),
              subtitle: const Text('For example: lunch 350 at Java yesterday'),
              onTap: () => Navigator.pop(context, AddExpenseChoice.quickAdd),
            ),
            ListTile(
              leading: const Icon(Icons.sms_outlined),
              title: const Text('Paste an M-Pesa message'),
              subtitle: const Text('Fill it in from the confirmation'),
              onTap: () => Navigator.pop(context, AddExpenseChoice.mpesa),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Choose a receipt file'),
              subtitle: const Text('A photo or a PDF'),
              onTap: () => Navigator.pop(context, AddExpenseChoice.scanFile),
            ),
            if (cameraEnabled)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo of a receipt'),
                subtitle: const Text('Use the camera'),
                onTap: () =>
                    Navigator.pop(context, AddExpenseChoice.scanCamera),
              ),
          ],
        ),
      ),
    );
  }
}
