import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/local_state_reset.dart';

/// Forgets everything kept in the app's saved preferences.
class SharedPreferencesReset implements LocalStateReset {
  SharedPreferencesReset(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<void> clear() async {
    try {
      await _preferences.clear();
    } on Object {
      // Nothing more can be done.
    }
  }
}
