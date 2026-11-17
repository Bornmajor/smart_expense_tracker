import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';

/// Shortcuts so widgets stay short: `context.scheme`, `context.text`, ...
extension ThemeX on BuildContext {
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppSemanticColors get semantic =>
      Theme.of(this).extension<AppSemanticColors>()!;
}
