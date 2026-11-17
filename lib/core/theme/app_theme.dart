import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.black,
      onPrimary: AppColors.white,
      secondary: AppColors.grey600,
      onSecondary: AppColors.white,
      error: AppColors.danger,
      onError: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.black,
      onSurfaceVariant: AppColors.grey600,
      outline: AppColors.grey200,
      surfaceContainerHighest: AppColors.grey50, // field background
    ),
    AppSemanticColors.light,
    scaffold: AppColors.grey50,
  );

  static ThemeData get dark => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.white,
      onPrimary: AppColors.black,
      secondary: AppColors.grey400,
      onSecondary: AppColors.black,
      error: Color(0xFFF87171),
      onError: AppColors.black,
      surface: AppColors.grey850,
      onSurface: AppColors.white,
      onSurfaceVariant: AppColors.grey400,
      outline: AppColors.grey800,
      surfaceContainerHighest: AppColors.grey800,
    ),
    AppSemanticColors.dark,
    scaffold: AppColors.black,
  );

  static ThemeData _build(
    ColorScheme s,
    AppSemanticColors semantic, {
    required Color scaffold,
  }) {
    final fieldBorder = OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide.none,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: s,
      scaffoldBackgroundColor: scaffold,
      fontFamily: AppTypography.fontFamily,
      textTheme: AppTypography.textTheme(s.onSurface, s.onSurfaceVariant),
      extensions: [semantic],

      // Every TextField / TextFormField in the app inherits this.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: s.primary, width: 1.5),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: s.error),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: s.error, width: 1.5),
        ),
        hintStyle: TextStyle(color: s.onSurfaceVariant.withValues(alpha: 0.7)),
      ),

      // Primary action: full-width black button.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: s.outline),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: s.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: s.onSurface,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: s.surface,
        indicatorColor: s.surfaceContainerHighest,
        elevation: 0,
      ),

      dividerTheme: DividerThemeData(color: s.outline, space: 1),
    );
  }
}
