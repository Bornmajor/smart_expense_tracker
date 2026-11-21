import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/quick_add_draft.dart';
import '../../domain/usecases/parse_quick_add.dart';

/// Bottom sheet where the user types one line, such as "lunch 350 at Java
/// yesterday", and sees what was understood as they type. Returns the line, or
/// null when the sheet is closed without continuing.
Future<String?> showQuickAddSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    // Above the tab bar and the Add button.
    useRootNavigator: true,
    builder: (context) => const _QuickAddSheet(),
  );
}

class _QuickAddSheet extends StatefulWidget {
  const _QuickAddSheet();

  @override
  State<_QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<_QuickAddSheet> {
  final _controller = TextEditingController();
  final _parse = ParseQuickAdd();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  QuickAddDraft get _draft => _parse(_controller.text);

  void _continue() {
    if (_draft.amountMinor == null) return;
    Navigator.pop(context, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.select<SettingsCubit, Currency>(
      (cubit) => cubit.state.currency,
    );
    final draft = _draft;
    final typed = _controller.text.trim().isNotEmpty;

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          Text('Type it in one line', style: context.text.titleLarge),
          const Gap(AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _continue(),
            decoration: const InputDecoration(
              hintText: 'lunch 350 at Java yesterday',
            ),
          ),
          const Gap(AppSpacing.md),
          if (!typed)
            Text(
              'Say what you spent, how much, where and when. For example '
              '"fuel 3000 at Shell on monday" or "ksh 1,200 airtime".',
              style: context.text.bodySmall,
            )
          else
            _Understood(draft: draft, currency: currency),
          const Gap(AppSpacing.lg),
          FilledButton(
            onPressed: draft.amountMinor == null ? null : _continue,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

/// What was found in the line, so a wrong guess can be fixed before the form.
class _Understood extends StatelessWidget {
  const _Understood({required this.draft, required this.currency});

  final QuickAddDraft draft;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final amount = draft.amountMinor;
    final date = draft.date;
    final chips = <Widget>[
      if (amount != null)
        Chip(label: Text(currency.format(amount)))
      else
        Chip(
          label: const Text('Add an amount, such as 350 or 1.5k'),
          backgroundColor: context.scheme.errorContainer,
        ),
      if (date != null) Chip(label: Text(DateFormat.MMMd().format(date))),
      if (draft.vendor.isNotEmpty) Chip(label: Text(draft.vendor)),
      if (draft.title.isNotEmpty) Chip(label: Text(draft.title)),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: chips,
    );
  }
}
