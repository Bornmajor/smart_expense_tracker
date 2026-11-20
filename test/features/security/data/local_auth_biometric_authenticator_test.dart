import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:smart_expense_tracker/features/security/data/repositories/local_auth_biometric_authenticator.dart';
import 'package:smart_expense_tracker/features/security/domain/entities/auth_outcome.dart';

/// Stands in for the plugin, so the mapping of every error can be checked
/// without a phone.
class _FakeLocalAuth implements LocalAuthentication {
  /// What `isDeviceSupported` returns, or throws when it is an Exception.
  Object supported = true;

  /// What `authenticate` returns (a bool), or throws when it is an Exception.
  Object result = true;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    switch (invocation.memberName) {
      case #isDeviceSupported:
        return _answer(supported);
      case #authenticate:
        return _answer(result);
    }
    return super.noSuchMethod(invocation);
  }

  Future<bool> _answer(Object value) =>
      value is Exception ? Future.error(value) : Future.value(value as bool);
}

void main() {
  late _FakeLocalAuth plugin;
  late LocalAuthBiometricAuthenticator authenticator;

  setUp(() {
    plugin = _FakeLocalAuth();
    authenticator = LocalAuthBiometricAuthenticator(plugin);
  });

  Future<AuthOutcome> check() => authenticator.authenticate(reason: 'Test');

  group('isAvailable', () {
    test('is true for a phone that can check the user', () async {
      expect(await authenticator.isAvailable(), isTrue);
    });

    test('is false for a phone that cannot', () async {
      plugin.supported = false;

      expect(await authenticator.isAvailable(), isFalse);
    });

    test('is false, not a crash, when the plugin fails', () async {
      plugin.supported = PlatformException(code: 'broken');

      expect(await authenticator.isAvailable(), isFalse);
    });
  });

  group('authenticate', () {
    test('passes', () async {
      expect(await check(), AuthOutcome.success);
    });

    test('a wrong fingerprint is a failed check, not an error', () async {
      plugin.result = false;

      expect(await check(), AuthOutcome.failed);
    });

    test(
      'a plugin failure means the phone cannot check, not a crash',
      () async {
        plugin.result = PlatformException(code: 'broken');

        expect(await check(), AuthOutcome.unavailable);
      },
    );
  });

  group('every plugin error code', () {
    // The point of this group: no code is left to chance. A user must never
    // end up on a lock screen that can neither open nor offer a way out.
    const expected = {
      LocalAuthExceptionCode.userCanceled: AuthOutcome.cancelled,
      LocalAuthExceptionCode.systemCanceled: AuthOutcome.cancelled,
      LocalAuthExceptionCode.timeout: AuthOutcome.cancelled,
      LocalAuthExceptionCode.authInProgress: AuthOutcome.cancelled,
      LocalAuthExceptionCode.userRequestedFallback: AuthOutcome.cancelled,
      LocalAuthExceptionCode.temporaryLockout: AuthOutcome.lockedOut,
      LocalAuthExceptionCode.biometricLockout: AuthOutcome.lockedOut,
      LocalAuthExceptionCode.uiUnavailable: AuthOutcome.failed,
      LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          AuthOutcome.failed,
      LocalAuthExceptionCode.noCredentialsSet: AuthOutcome.unavailable,
      LocalAuthExceptionCode.noBiometricsEnrolled: AuthOutcome.unavailable,
      LocalAuthExceptionCode.noBiometricHardware: AuthOutcome.unavailable,
      LocalAuthExceptionCode.deviceError: AuthOutcome.unavailable,
      LocalAuthExceptionCode.unknownError: AuthOutcome.unavailable,
    };

    test('is covered by this test', () {
      expect(expected.keys.toSet(), LocalAuthExceptionCode.values.toSet());
    });

    for (final entry in expected.entries) {
      test('${entry.key.name} is ${entry.value.name}', () async {
        plugin.result = LocalAuthException(code: entry.key);

        expect(await check(), entry.value);
      });
    }
  });
}
