import '../entities/auth_outcome.dart';

abstract interface class BiometricAuthenticator {
  /// True when the phone can check the user: it has a fingerprint or face set
  /// up, or at least a screen lock (PIN, pattern or password) to fall back on.
  Future<bool> isAvailable();

  /// Shows the system prompt and says how it ended. It never throws: every
  /// problem is one of the [AuthOutcome]s.
  Future<AuthOutcome> authenticate({required String reason});
}
