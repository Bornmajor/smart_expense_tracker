import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/security/domain/usecases/enable_biometric_lock.dart';
import 'package:smart_expense_tracker/features/security/presentation/cubit/security_cubit.dart';
import 'package:smart_expense_tracker/features/security/presentation/cubit/security_state.dart';
import 'package:smart_expense_tracker/features/security/presentation/lock_session.dart';

import '../../../../support/fakes.dart';

void main() {
  late FakeSecurityRepository repository;
  late LockSession session;

  SecurityCubit cubit(FakeBiometricAuthenticator authenticator) =>
      SecurityCubit(
        repository,
        EnableBiometricLock(repository, authenticator),
        session,
      );

  setUp(() {
    repository = FakeSecurityRepository();
    session = LockSession(enabled: false);
  });

  group('SecurityCubit', () {
    test('starts with the saved setting', () {
      repository.enabled = true;

      expect(cubit(FakeBiometricAuthenticator()).state.enabled, isTrue);
    });

    blocTest<SecurityCubit, SecurityState>(
      'turns the lock on and reports it',
      build: () => cubit(FakeBiometricAuthenticator()),
      act: (c) => c.setBiometricEnabled(true),
      expect: () => const [
        SecurityState(
          enabled: true,
          feedback: SecurityFeedback.turnedOn,
          attempt: 1,
        ),
      ],
      verify: (_) {
        expect(repository.enabled, isTrue);
        expect(session.isLocked, isFalse);
      },
    );

    blocTest<SecurityCubit, SecurityState>(
      'reports when biometrics are not available',
      build: () => cubit(FakeBiometricAuthenticator(available: false)),
      act: (c) => c.setBiometricEnabled(true),
      expect: () => const [
        SecurityState(
          enabled: false,
          feedback: SecurityFeedback.unavailable,
          attempt: 1,
        ),
      ],
      verify: (_) => expect(repository.enabled, isFalse),
    );

    blocTest<SecurityCubit, SecurityState>(
      'reports a failed check and stays off',
      build: () => cubit(FakeBiometricAuthenticator(succeeds: false)),
      act: (c) => c.setBiometricEnabled(true),
      expect: () => const [
        SecurityState(
          enabled: false,
          feedback: SecurityFeedback.failed,
          attempt: 1,
        ),
      ],
    );

    blocTest<SecurityCubit, SecurityState>(
      'turns the lock off and reports it',
      build: () {
        repository.enabled = true;
        session = LockSession(enabled: true);
        return cubit(FakeBiometricAuthenticator());
      },
      act: (c) => c.setBiometricEnabled(false),
      expect: () => const [
        SecurityState(
          enabled: false,
          feedback: SecurityFeedback.turnedOff,
          attempt: 1,
        ),
      ],
      verify: (_) {
        expect(repository.enabled, isFalse);
        expect(session.isLocked, isFalse);
      },
    );

    blocTest<SecurityCubit, SecurityState>(
      'counts repeated results so each one is reported',
      build: () => cubit(FakeBiometricAuthenticator(succeeds: false)),
      act: (c) async {
        await c.setBiometricEnabled(true);
        await c.setBiometricEnabled(true);
      },
      expect: () => const [
        SecurityState(
          enabled: false,
          feedback: SecurityFeedback.failed,
          attempt: 1,
        ),
        SecurityState(
          enabled: false,
          feedback: SecurityFeedback.failed,
          attempt: 2,
        ),
      ],
    );
  });
}
