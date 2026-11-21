import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/app/restart_widget.dart';

/// Builds a new state every time the app is started again.
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('taps $taps'),
      TextButton(
        onPressed: () => setState(() => taps++),
        child: const Text('tap'),
      ),
      Builder(
        builder: (context) => TextButton(
          onPressed: () => RestartWidget.restart(context),
          child: const Text('restart'),
        ),
      ),
    ],
  );
}

void main() {
  testWidgets('starting again builds everything new', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RestartWidget(child: _Counter())),
    );
    await tester.tap(find.text('tap'));
    await tester.tap(find.text('tap'));
    await tester.pump();
    expect(find.text('taps 2'), findsOneWidget);

    await tester.tap(find.text('restart'));
    await tester.pump();

    expect(find.text('taps 0'), findsOneWidget);
  });

  testWidgets('with nothing to restart it says so and does nothing', (
    tester,
  ) async {
    late bool restarted;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            restarted = RestartWidget.restart(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(restarted, isFalse);
  });
}
