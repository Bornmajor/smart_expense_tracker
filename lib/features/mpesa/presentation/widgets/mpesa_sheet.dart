import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/mpesa_transaction.dart';
import '../../domain/usecases/parse_mpesa.dart';

/// Bottom sheet where the user pastes an M-Pesa confirmation message and sees
/// what was read from it. Returns the message, or null when the sheet is closed
/// without continuing. The app never reads the user's SMS: the message only
/// comes in when the user pastes it.
Future<String?> showMpesaSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    // Above the tab bar and the Add button.
    useRootNavigator: true,
    builder: (context) => const _MpesaSheet(),
  );
}

class _MpesaSheet extends StatefulWidget {
  const _MpesaSheet();

  @override
  State<_MpesaSheet> createState() => _MpesaSheetState();
}

class _MpesaSheetState extends State<_MpesaSheet> {
  final _controller = TextEditingController();
  static const _parse = ParseMpesa();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  MpesaTransaction? get _transaction => _parse(_controller.text);

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted || data?.text == null) return;
    setState(() => _controller.text = data!.text!);
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.select<SettingsCubit, Currency>(
      (cubit) => cubit.state.currency,
    );
    final typed = _controller.text.trim().isNotEmpty;
    final transaction = _transaction;
    final usable = transaction != null && !transaction.isIncome;

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
          Text('Paste an M-Pesa message', style: context.text.titleLarge),
          const Gap(AppSpacing.sm),
          Text(
            'Copy the confirmation message from your messages app and paste '
            'it here. The app never reads your messages by itself.',
            style: context.text.bodySmall,
          ),
          const Gap(AppSpacing.md),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'SGH4A1B2C3 Confirmed. Ksh500.00 sent to…',
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _paste,
              icon: const Icon(Icons.content_paste, size: 18),
              label: const Text('Paste'),
            ),
          ),
          if (typed) ...[
            const Gap(AppSpacing.sm),
            _Understood(transaction: transaction, currency: currency),
          ],
          const Gap(AppSpacing.lg),
          FilledButton(
            onPressed: usable
                ? () => Navigator.pop(context, _controller.text)
                : null,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _Understood extends StatelessWidget {
  const _Understood({required this.transaction, required this.currency});

  final MpesaTransaction? transaction;
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    if (t == null) {
      return Text(
        'No amount found. Paste the whole M-Pesa message.',
        style: context.text.bodyMedium?.copyWith(color: context.scheme.error),
      );
    }
    if (t.isIncome) {
      return Text(
        'This is money you received. SpendWise IQ records what you spend.',
        style: context.text.bodyMedium,
      );
    }

    final total = t.amountMinor + (t.costMinor ?? 0);
    final date = t.date;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        Chip(label: Text(currency.format(total))),
        if (t.counterparty.isNotEmpty) Chip(label: Text(t.counterparty)),
        if (date != null) Chip(label: Text(DateFormat.MMMd().format(date))),
        if (t.costMinor != null)
          Chip(label: Text('incl. ${currency.format(t.costMinor!)} cost')),
      ],
    );
  }
}
