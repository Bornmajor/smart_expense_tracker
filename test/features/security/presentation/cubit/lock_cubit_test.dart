import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
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
