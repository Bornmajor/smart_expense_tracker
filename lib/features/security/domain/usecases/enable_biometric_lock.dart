import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../entities/auth_outcome.dart';
import '../repositories/biometric_authenticator.dart';
import '../repositories/security_repository.dart';

/// Turns the lock on, but only after the phone confirms the user. This stops
/// the lock from being switched on when it could never be opened.
class EnableBiometricLock {
  EnableBiometricLock(this._security, this._authenticator);

  final SecurityRepository _security;
  final BiometricAuthenticator _authenticator;

  Future<Result<void>> call() async {
    if (!await _authenticator.isAvailable()) {
      return const Failure(BiometricUnavailableFailure());
    }

    final outcome = await _authenticator.authenticate(
      reason: 'Confirm it\'s you to turn on the lock',
    );
    switch (outcome) {
      case AuthOutcome.success:
        await _security.setBiometricEnabled(true);
        return const Success(null);
      case AuthOutcome.unavailable:
        return const Failure(BiometricUnavailableFailure());
      case AuthOutcome.failed || AuthOutcome.cancelled || AuthOutcome.lockedOut:
        return const Failure(AuthenticationFailure());
    }
  }
}
