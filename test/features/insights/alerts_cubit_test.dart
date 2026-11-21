import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expense_tracker/features/insights/data/repositories/alert_dismissals_impl.dart';
import 'package:smart_expense_tracker/features/insights/domain/entities/insight_alert.dart';
import 'package:smart_expense_tracker/features/insights/presentation/cubit/alerts_cubit.dart';

import '../../support/builders.dart';
import '../../support/fakes.dart';

void main() {
  final today = DateTime(2026, 11, 20);

  late FakeExpenseRepository repository;
  late FakeAlertDismissals dismissals;

  FakeExpenseRepository twoCharges() => FakeExpenseRepository(
    initial: [
      buildExpense(id: 'a', amountMinor: 50000, date: DateTime(2026, 11, 19)),
      buildExpense(id: 'b', amountMinor: 50000, date: DateTime(2026, 11, 20)),
    ],
  );

  Future<AlertsCubit> start() async {
    final cubit = AlertsCubit(
      repository,
      dismissals,
      FakeBudgetRepository(),
      now: () => today,
    );
    addTearDown(cubit.close);
    await pumpEventQueue();
    return cubit;
  }

  setUp(() {
    repository = twoCharges();
    dismissals = FakeAlertDismissals();
  });

  group('AlertsCubit', () {
    test('shows the alerts found in the expenses', () async {
      final cubit = await start();

      expect(cubit.state.single.kind, AlertKind.possibleDuplicate);
    });

    test('has none when nothing looks odd', () async {
      repository = FakeExpenseRepository(initial: [buildExpense()]);

      final cubit = await start();

      expect(cubit.state, isEmpty);
    });

    test('a dismissed alert goes and stays gone', () async {
      final cubit = await start();

      await cubit.dismiss(cubit.state.single.id);

      expect(cubit.state, isEmpty);
      final again = await start();
      expect(again.state, isEmpty);
    });

    test('follows new expenses', () async {
      repository = FakeExpenseRepository(
        initial: [
          buildExpense(
            id: 'a',
            amountMinor: 50000,
            date: DateTime(2026, 11, 19),
          ),
        ],
      );
      final cubit = await start();
      expect(cubit.state, isEmpty);

      await repository.save(
        buildExpense(id: 'b', amountMinor: 50000, date: DateTime(2026, 11, 20)),
      );
      await pumpEventQueue();

      expect(cubit.state, hasLength(1));
    });
  });

  group('AlertDismissalsImpl', () {
    late SharedPreferences preferences;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = await SharedPreferences.getInstance();
    });

    test('remembers what was dismissed', () async {
      await AlertDismissalsImpl(preferences).dismiss('dup:1');

      expect(AlertDismissalsImpl(preferences).dismissed(), {'dup:1'});
    });

    test('does not list the same one twice', () async {
      final impl = AlertDismissalsImpl(preferences);
      await impl.dismiss('dup:1');
      await impl.dismiss('dup:1');

      expect(preferences.getStringList('dismissed_alerts'), ['dup:1']);
    });

    test('forgets the oldest past a hundred', () async {
      final impl = AlertDismissalsImpl(preferences);
      for (var i = 0; i < 105; i++) {
        await impl.dismiss('id$i');
      }

      final kept = impl.dismissed();
      expect(kept, hasLength(100));
      expect(kept.contains('id0'), isFalse);
      expect(kept.contains('id104'), isTrue);
    });
  });
}
