import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show appFlavor;

/// Developer tools exist only in debug builds and in the dev flavor. A release
/// of the prod flavor (what testers and the store get) never has them.
bool get developerToolsEnabled => kDebugMode || appFlavor == 'dev';

/// The date the app treats as today when recurring expenses are added.
///
/// Used by the developer tool "Pretend today is", to check that a bill is added
/// on its due date without waiting a month. It is kept in memory only, so
/// closing the app always returns to the real date.
abstract final class TestClock {
  static DateTime? _pretend;

  /// The pretend date, or null while the real date is used.
  static DateTime? get pretend => _pretend;

  /// Only works where [developerToolsEnabled]. Anywhere else it does nothing,
  /// so a stray call can never change the date for a real user.
  static void pretendTodayIs(DateTime? date) {
    if (!developerToolsEnabled) return;
    _pretend = date;
  }

  static DateTime now() {
    final pretend = _pretend;
    if (pretend == null) return DateTime.now();
    final real = DateTime.now();
    // The pretend day, at the real time of day.
    return DateTime(
      pretend.year,
      pretend.month,
      pretend.day,
      real.hour,
      real.minute,
      real.second,
    );
  }
}
