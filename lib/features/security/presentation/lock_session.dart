import 'package:flutter/foundation.dart';

/// Tracks whether the app is locked during this run. The router listens to it,
/// so locking or unlocking moves the user between the lock screen and the app.
class LockSession extends ChangeNotifier {
  LockSession({
    required bool enabled,
    this._gracePeriod = const Duration(seconds: 30),
    DateTime Function()? now,
  }) : _enabled = enabled,
       _unlocked = !enabled,
       _now = now ?? DateTime.now;

  final Duration _gracePeriod;
  final DateTime Function() _now;

  bool _enabled;
  bool _unlocked;
  DateTime? _leftAt;

  /// True when the lock is on and the user has not unlocked yet.
  bool get isLocked => _enabled && !_unlocked;

  /// Called when the user turns the lock on or off in Settings.
  /// They are already inside the app, so it stays unlocked until backgrounded.
  void setEnabled(bool enabled) {
    _enabled = enabled;
    _unlocked = true;
    notifyListeners();
  }

  void unlock() {
    if (_unlocked) return;
    _unlocked = true;
    notifyListeners();
  }

  void didEnterBackground() => _leftAt = _now();

  /// Locks again if the app was away longer than the grace period.
  /// A short trip (for example to the camera) does not ask for a check.
  void didReturnToForeground() {
    final leftAt = _leftAt;
    _leftAt = null;
    if (!_enabled || leftAt == null) return;
    if (_now().difference(leftAt) >= _gracePeriod) {
      _unlocked = false;
      notifyListeners();
    }
  }
}
