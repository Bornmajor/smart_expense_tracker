import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/restart_widget.dart';
import 'core/database/app_database.dart';
import 'core/info/app_version.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final info = await PackageInfo.fromPlatform();
  final database = AppDatabase.local();
  runApp(
    RestartWidget(
      child: SpendWiseApp(
        database: database,
        preferences: preferences,
        appVersion: AppVersion(name: info.version, build: info.buildNumber),
      ),
    ),
  );
}
