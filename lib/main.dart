import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/database/app_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(SpendWiseApp(database: AppDatabase.local()));
}
