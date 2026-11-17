import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/theme_preview_screen.dart';

class SpendWiseApp extends StatelessWidget {
  const SpendWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise IQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // follows the phone; settings toggle later
      // Temporary: replaced by the welcome screen in the next step.
      home: const ThemePreviewScreen(),
    );
  }
}
