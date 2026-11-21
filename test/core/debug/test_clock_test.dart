import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/debug/test_clock.dart';

void main() {
  tearDown(() => TestClock.pretendTodayIs(null));

  test('uses the real date until told to pretend', () {
    expect(TestClock.pretend, isNull);
    final before = DateTime.now();
    final now = TestClock.now();
    expect(now.difference(before).inSeconds.abs(), lessThan(2));
  });

  test('pretends the chosen day and goes back to the real date', () {
    TestClock.pretendTodayIs(DateTime(2027, 1, 5));

    expect(TestClock.now().year, 2027);
    expect(TestClock.now().month, 1);
    expect(TestClock.now().day, 5);

    TestClock.pretendTodayIs(null);

    expect(TestClock.pretend, isNull);
    expect(TestClock.now().year, DateTime.now().year);
  });
}
