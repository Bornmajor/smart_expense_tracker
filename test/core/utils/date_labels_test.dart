import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/utils/date_labels.dart';

void main() {
  final now = DateTime(2026, 11, 17, 15, 30);

  group('dayLabel', () {
    test('says Today and Yesterday', () {
      expect(dayLabel(DateTime(2026, 11, 17), now), 'Today');
      expect(dayLabel(DateTime(2026, 11, 16), now), 'Yesterday');
    });

    test('ignores the time of day', () {
      expect(dayLabel(DateTime(2026, 11, 17, 23, 59), now), 'Today');
      expect(dayLabel(DateTime(2026, 11, 16, 0, 1), now), 'Yesterday');
    });

    test('uses a short date for older days this year', () {
      expect(dayLabel(DateTime(2026, 11, 10), now), 'Tue, Nov 10');
    });

    test('adds the year for days in other years', () {
      expect(dayLabel(DateTime(2025, 12, 31), now), 'Wed, Dec 31, 2025');
    });

    test('says Yesterday across a month boundary', () {
      expect(
        dayLabel(DateTime(2026, 10, 31), DateTime(2026, 11, 1, 8)),
        'Yesterday',
      );
    });
  });
}
