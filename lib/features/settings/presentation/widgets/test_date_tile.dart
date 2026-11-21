import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/debug/test_clock.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../recurring/domain/usecases/generate_due_expenses.dart';

/// TEMPORARY developer tool: pretend it is another day, so a recurring bill
/// can be seen being added without waiting for the real date. Shown only where
/// [developerToolsEnabled]. The pretend date is forgotten when the app closes.
class TestDateTile extends StatefulWidget {
  const TestDateTile({super.key});

  @override
  State<TestDateTile> createState() => _TestDateTileState();
}

class _TestDateTileState extends State<TestDateTile> {
  Future<void> _choose() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: TestClock.pretend ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Pretend today is',
    );
    if (picked == null || !mounted) return;
    await _apply(picked);
  }

  Future<void> _apply(DateTime? date) async {
    TestClock.pretendTodayIs(date);
    final added = await context.read<GenerateDueExpenses>()();
    if (!mounted) return;
    setState(() {});
    context.showSuccess(
      added == 0
          ? 'No recurring expense was due'
          : 'Added $added recurring expense${added == 1 ? '' : 's'}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final pretend = TestClock.pretend;
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.event_repeat_outlined),
            title: const Text('Pretend today is'),
            subtitle: Text(
              pretend == null
                  ? 'Using the real date. Tap to pick a day, then due recurring '
                        'expenses are added.'
                  : '${pretend.year}-${pretend.month.toString().padLeft(2, '0')}-'
                        '${pretend.day.toString().padLeft(2, '0')}',
            ),
            onTap: _choose,
          ),
          if (pretend != null)
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Use the real date'),
              onTap: () => _apply(null),
            ),
        ],
      ),
    );
  }
}
