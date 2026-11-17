import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/security/presentation/lock_session.dart';

void main() {
  var clock = DateTime(2026, 11, 17, 12);

  LockSession session({required bool enabled}) => LockSession(
    enabled: enabled,
    gracePeriod: const Duration(seconds: 30),
    now: () => clock,
  );

  setUp(() => clock = DateTime(2026, 11, 17, 12));

  group('LockSession', () {
    test('starts locked only when the lock is on', () {
      expect(session(enabled: true).isLocked, isTrue);
      expect(session(enabled: false).isLocked, isFalse);
    });

    test('unlock opens the app and notifies listeners once', () {
      final s = session(enabled: true);
      var notifications = 0;
      s.addListener(() => notifications++);

      s.unlock();
      s.unlock();

      expect(s.isLocked, isFalse);
      expect(notifications, 1);
    });

    test('turning the lock on from Settings does not lock the user out', () {
      final s = session(enabled: false);

      s.setEnabled(true);

      expect(s.isLocked, isFalse);
    });

    test('turning the lock off unlocks the app', () {
      final s = session(enabled: true);

      s.setEnabled(false);

      expect(s.isLocked, isFalse);
    });

    test('does not lock after a short trip away', () {
      final s = session(enabled: true)..unlock();

      s.didEnterBackground();
      clock = clock.add(const Duration(seconds: 29));
      s.didReturnToForeground();

      expect(s.isLocked, isFalse);
    });

    test('locks again after the grace period', () {
      final s = session(enabled: true)..unlock();
      var notified = false;
      s.addListener(() => notified = true);

      s.didEnterBackground();
      clock = clock.add(const Duration(seconds: 30));
      s.didReturnToForeground();

      expect(s.isLocked, isTrue);
      expect(notified, isTrue);
    });

    test('never locks when the lock is off, however long the app is away', () {
      final s = session(enabled: false);

      s.didEnterBackground();
      clock = clock.add(const Duration(hours: 3));
      s.didReturnToForeground();

      expect(s.isLocked, isFalse);
    });

    test('ignores a return that has no matching departure', () {
      final s = session(enabled: true)..unlock();

      s.didReturnToForeground();

      expect(s.isLocked, isFalse);
    });
  });
}
