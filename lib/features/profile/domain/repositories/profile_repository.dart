/// What the app knows about the person using it. For now only a first name,
/// which is optional, stays on the phone, and is used to greet them.
abstract interface class ProfileRepository {
  /// The name, or an empty string when none was given.
  String get name;

  /// Saves the name, tidied up. A blank name clears it.
  Future<void> setName(String name);
}
