import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/database/app_database.dart';
import 'core/info/app_version.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final info = await PackageInfo.fromPlatform();
  runApp(
    SpendWiseApp(
      database: AppDatabase.local(),
      preferences: preferences,
      appVersion: AppVersion(name: info.version, build: info.buildNumber),
    ),
  );
}
