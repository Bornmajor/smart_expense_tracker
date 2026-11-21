import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/backup_history.dart';

class BackupHistoryImpl implements BackupHistory {
  BackupHistoryImpl(this._preferences);

  static const _key = 'last_backup_at';

  final SharedPreferences _preferences;

  @override
  DateTime? lastBackupAt() {
    try {
      final millis = _preferences.getInt(_key);
      return millis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(millis);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> record(DateTime when) async {
    try {
      await _preferences.setInt(_key, when.millisecondsSinceEpoch);
    } on Object {
      // Nothing to do.
    }
  }
}
