import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/alert_dismissals.dart';

class AlertDismissalsImpl implements AlertDismissals {
  AlertDismissalsImpl(this._preferences);

  static const _key = 'dismissed_alerts';

  /// Old ones are forgotten past this many, since an old alert never returns.
  static const _keep = 100;

  final SharedPreferences _preferences;

  @override
  Set<String> dismissed() {
    try {
      return (_preferences.getStringList(_key) ?? const []).toSet();
    } on Object {
      return {};
    }
  }

  @override
  Future<void> dismiss(String id) async {
    try {
      final list = _preferences.getStringList(_key) ?? <String>[];
      if (list.contains(id)) return;
      final updated = [...list, id];
      await _preferences.setStringList(
        _key,
        updated.length > _keep
            ? updated.sublist(updated.length - _keep)
            : updated,
      );
    } on Object {
      // Nothing to do: the alert may simply show again.
    }
  }
}
