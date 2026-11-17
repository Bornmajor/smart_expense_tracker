import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/core/errors/result.dart';
import 'package:smart_expense_tracker/features/security/domain/usecases/enable_biometric_lock.dart';

import '../../../support/fakes.dart';

void main() {
  late FakeSecurityRepository security;

  EnableBiometricLock useCase(FakeBiometricAuthenticator authenticator) =>
      EnableBiometricLock(security, authenticator);

  setUp(() => security = FakeSecurityRepository());

  group('EnableBiometricLock', () {
    test('turns the lock on after the user is confirmed', () async {
      final result = await useCase(FakeBiometricAuthenticator())();

      expect(result, isA<Success<void>>());
      expect(security.enabled, isTrue);
    });

    test('refuses when no biometrics are set up, without prompting', () async {
      final authenticator = FakeBiometricAuthenticator(available: false);

      final result = await useCase(authenticator)();

      expect(
        (result as Failure<void>).failure,
        const BiometricUnavailableFailure(),
      );
      expect(authenticator.authenticateCalls, 0);
      expect(security.enabled, isFalse);
    });

    test('refuses when the user fails or cancels the check', () async {
      final result = await useCase(
        FakeBiometricAuthenticator(succeeds: false),
      )();

      expect((result as Failure<void>).failure, const AuthenticationFailure());
      expect(security.enabled, isFalse);
    });
  });
}
