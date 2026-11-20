import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/security/domain/entities/auth_outcome.dart';
import 'package:smart_expense_tracker/features/security/presentation/cubit/lock_cubit.dart';
import 'package:smart_expense_tracker/features/security/presentation/cubit/lock_state.dart';
import 'package:smart_expense_tracker/features/security/presentation/lock_session.dart';

import '../../../../support/fakes.dart';

void main() {
  late LockSession session;

  setUp(() => session = LockSession(enabled: true));

  group('LockCubit', () {
    blocTest<LockCubit, LockScreenState>(
      'unlocks the session when the check succeeds',
      build: () => LockCubit(FakeBiometricAuthenticator(), session),
      act: (c) => c.authenticate(),
      expect: () => const [
        LockScreenState(status: LockStatus.authenticating),
        LockScreenState(),
      ],
      verify: (_) => expect(session.isLocked, isFalse),
    );

    blocTest<LockCubit, LockScreenState>(
      'stays locked and reports a failed check',
      build: () =>
          LockCubit(FakeBiometricAuthenticator(succeeds: false), session),
      act: (c) => c.authenticate(),
      expect: () => const [
        LockScreenState(status: LockStatus.authenticating),
        LockScreenState(status: LockStatus.failed, attempt: 1),
      ],
      verify: (_) => expect(session.isLocked, isTrue),
    );

    blocTest<LockCubit, LockScreenState>(
      'a closed prompt shows nothing and stays locked',
      build: () => LockCubit(
        FakeBiometricAuthenticator()..outcome = AuthOutcome.cancelled,
        session,
      ),
      act: (c) => c.authenticate(),
      expect: () => const [
        LockScreenState(status: LockStatus.authenticating),
        LockScreenState(),
      ],
      verify: (_) => expect(session.isLocked, isTrue),
    );

    blocTest<LockCubit, LockScreenState>(
      'too many tries is reported as a lock-out, and stays locked',
      build: () => LockCubit(
        FakeBiometricAuthenticator()..outcome = AuthOutcome.lockedOut,
        session,
      ),
      act: (c) => c.authenticate(),
      expect: () => const [
        LockScreenState(status: LockStatus.authenticating),
        LockScreenState(status: LockStatus.lockedOut, attempt: 1),
      ],
      verify: (_) => expect(session.isLocked, isTrue),
    );

    blocTest<LockCubit, LockScreenState>(
      'a phone that cannot check is reported, so the screen can offer a way out',
      build: () => LockCubit(
        FakeBiometricAuthenticator()..outcome = AuthOutcome.unavailable,
        session,
      ),
      act: (c) => c.authenticate(),
      expect: () => const [
        LockScreenState(status: LockStatus.authenticating),
        LockScreenState(status: LockStatus.unavailable, attempt: 1),
      ],
      verify: (_) => expect(session.isLocked, isTrue),
    );

    test('can try again after a phone problem and get in', () async {
      final authenticator = FakeBiometricAuthenticator()
        ..outcome = AuthOutcome.unavailable;
      final cubit = LockCubit(authenticator, session);
      await cubit.authenticate();
      expect(session.isLocked, isTrue);

      // The user sets up a screen lock again, then taps "Try again".
      authenticator.outcome = null;
      await cubit.authenticate();

      expect(session.isLocked, isFalse);
      await cubit.close();
    });

    blocTest<LockCubit, LockScreenState>(
      'does not start a second check while one is running',
      build: () => LockCubit(FakeBiometricAuthenticator(), session),
      act: (c) async {
        final first = c.authenticate();
        await c.authenticate();
        await first;
      },
      verify: (_) => expect(session.isLocked, isFalse),
    );
  });
}
