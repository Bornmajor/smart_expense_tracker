abstract interface class SecurityRepository {
  bool get isBiometricEnabled;

  Future<void> setBiometricEnabled(bool enabled);
}
