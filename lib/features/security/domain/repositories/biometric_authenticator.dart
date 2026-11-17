abstract interface class BiometricAuthenticator {
  /// True when the device supports biometrics and the user has enrolled some.
  Future<bool> isAvailable();

  /// Shows the system prompt. Returns false if the user cancels or fails.
  Future<bool> authenticate({required String reason});
}
