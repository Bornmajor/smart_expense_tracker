import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/app_theme_mode.dart';

class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AppThemeMode selected;
  final ValueChanged<AppThemeMode> onChanged;

  /// One line that shrinks to fit instead of wrapping, so a longer word such
  /// as "System" or a larger text size never pushes onto a second line.
  static Widget _label(String text) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, maxLines: 1, softWrap: false),
  );

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<AppThemeMode>(
      showSelectedIcon: false,
      style: SegmentedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      segments: [
        ButtonSegment(
          value: AppThemeMode.system,
          label: _label('System'),
          icon: const Icon(Icons.brightness_auto_outlined),
        ),
        ButtonSegment(
          value: AppThemeMode.light,
          label: _label('Light'),
          icon: const Icon(Icons.light_mode_outlined),
        ),
        ButtonSegment(
          value: AppThemeMode.dark,
          label: _label('Dark'),
          icon: const Icon(Icons.dark_mode_outlined),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (modes) => onChanged(modes.first),
    );
  }
}
