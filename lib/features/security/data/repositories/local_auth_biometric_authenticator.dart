import 'package:local_auth/local_auth.dart';

import '../../domain/entities/auth_outcome.dart';
import '../../domain/repositories/biometric_authenticator.dart';

/// The check through the `local_auth` plugin. The system prompt also offers the
/// phone's own PIN, pattern or password when a fingerprint or face does not
/// work, so a phone with only a screen lock can still use the app lock.
class LocalAuthBiometricAuthenticator implements BiometricAuthenticator {
  LocalAuthBiometricAuthenticator([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// True when the phone can check the user with a biometric or its screen
  /// lock. Asking only for enrolled biometrics would wrongly turn away a phone
  /// that has just a PIN.
  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on Exception {
      return false;
    }
  }

  @override
  Future<AuthOutcome> authenticate({required String reason}) async {
    try {
      final verified = await _auth.authenticate(localizedReason: reason);
      return verified ? AuthOutcome.success : AuthOutcome.failed;
    } on LocalAuthException catch (e) {
      return outcomeFor(e.code);
    } on Exception {
      // The plugin itself failed (for example it is missing on this phone).
      return AuthOutcome.unavailable;
    }
  }

  /// What a plugin error means for the user. A code the plugin adds in the
  /// future would not compile here, so it cannot be forgotten, and an unknown
  /// error counts as "this phone cannot check", so the lock screen offers a way
  /// out and the user is never stuck.
  static AuthOutcome outcomeFor(LocalAuthExceptionCode code) => switch (code) {
    LocalAuthExceptionCode.userCanceled ||
    LocalAuthExceptionCode.systemCanceled ||
    LocalAuthExceptionCode.timeout ||
    LocalAuthExceptionCode.authInProgress ||
    LocalAuthExceptionCode.userRequestedFallback => AuthOutcome.cancelled,

    LocalAuthExceptionCode.temporaryLockout ||
    LocalAuthExceptionCode.biometricLockout => AuthOutcome.lockedOut,

    // These pass, so trying again is the right answer.
    LocalAuthExceptionCode.uiUnavailable ||
    LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
      AuthOutcome.failed,

    LocalAuthExceptionCode.noCredentialsSet ||
    LocalAuthExceptionCode.noBiometricsEnrolled ||
    LocalAuthExceptionCode.noBiometricHardware ||
    LocalAuthExceptionCode.deviceError ||
    LocalAuthExceptionCode.unknownError => AuthOutcome.unavailable,
  };
}
