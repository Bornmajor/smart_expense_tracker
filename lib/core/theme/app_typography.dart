import 'package:flutter/material.dart';

abstract final class AppTypography {
  /// The bundled Inter font (see assets/fonts and pubspec.yaml).
  static const fontFamily = 'Inter';

  static TextTheme textTheme(Color primary, Color secondary) => TextTheme(
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: primary,
      height: 1.2,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    titleMedium: TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: primary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: primary,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: secondary,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: secondary,
    ),
    labelLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );
}
