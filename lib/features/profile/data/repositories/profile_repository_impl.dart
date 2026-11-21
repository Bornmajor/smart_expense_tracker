import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._preferences);

  static const _key = 'profile_name';

  /// Long enough for any first name, short enough to fit a greeting.
  static const maxLength = 30;

  final SharedPreferences _preferences;

  /// Spaces trimmed and made single, and cut to [maxLength].
  static String tidy(String name) {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    return clean.length > maxLength
        ? clean.substring(0, maxLength).trim()
        : clean;
  }

  @override
  String get name {
    try {
      return _preferences.getString(_key) ?? '';
    } on Object {
      return '';
    }
  }

  @override
  Future<void> setName(String name) async {
    final clean = tidy(name);
    try {
      if (clean.isEmpty) {
        await _preferences.remove(_key);
      } else {
        await _preferences.setString(_key, clean);
      }
    } on Object {
      // The greeting is a nicety; nothing else depends on it.
    }
  }
}
