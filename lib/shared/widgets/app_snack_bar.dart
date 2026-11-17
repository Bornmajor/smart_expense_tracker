import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/theme_x.dart';
import '../../core/utils/color_contrast.dart';

enum AppSnackBarKind { success, warning, error, info }

/// Builds a snackbar with a leading icon. Success, warning and error use the
/// theme's status colors; the text and icon switch between black and white,
/// whichever reads better on that color, in both light and dark mode.
SnackBar buildAppSnackBar(
  BuildContext context,
  AppSnackBarKind kind,
  String message,
) {
  final semantic = context.semantic;
  final (background, icon) = switch (kind) {
    AppSnackBarKind.success => (semantic.success, Icons.check_circle_outline),
    AppSnackBarKind.warning => (semantic.warning, Icons.warning_amber_rounded),
    AppSnackBarKind.error => (semantic.danger, Icons.error_outline),
    AppSnackBarKind.info => (context.scheme.onSurface, Icons.info_outline),
  };
  final foreground = kind == AppSnackBarKind.info
      ? context.scheme.surface
      : readableOn(background);

  return SnackBar(
    backgroundColor: background,
    content: Row(
      children: [
        Icon(icon, color: foreground),
        const Gap(AppSpacing.md),
        Expanded(
          child: Text(
            message,
            style: context.text.bodyMedium?.copyWith(color: foreground),
          ),
        ),
      ],
    ),
  );
}

/// `context.showSuccess('Saved')`, `showWarning`, `showError` and `showInfo`.
/// A new message replaces the one on screen.
extension AppSnackBars on BuildContext {
  void showSuccess(String message) => _show(AppSnackBarKind.success, message);

  void showWarning(String message) => _show(AppSnackBarKind.warning, message);

  void showError(String message) => _show(AppSnackBarKind.error, message);

  void showInfo(String message) => _show(AppSnackBarKind.info, message);

  void _show(AppSnackBarKind kind, String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(buildAppSnackBar(this, kind, message));
  }
}
