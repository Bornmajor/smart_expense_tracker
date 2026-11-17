import 'package:flutter/material.dart';

/// Raw palette. Nothing outside the theme folder should reference these;
/// widgets read colors from `Theme.of(context)` (see theme_x.dart).
abstract final class AppColors {
  // Brand
  static const black = Color(0xFF0A0A0A);
  static const white = Color(0xFFFFFFFF);

  // Neutrals
  static const grey50 = Color(0xFFF7F7F5); // screen / field background
  static const grey100 = Color(0xFFEFEFEC);
  static const grey200 = Color(0xFFE2E2DE); // borders, dividers
  static const grey400 = Color(0xFF9A9A9A); // hints
  static const grey600 = Color(0xFF6B6B6B); // body text
  static const grey800 = Color(0xFF222222); // dark field / border
  static const grey850 = Color(0xFF161616); // dark surface

  // Semantic (status only, never decoration)
  static const success = Color(0xFF1F9D55);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
}
