import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/currency.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../cubit/settings_cubit.dart';
import 'currency_sheet.dart';

/// A Settings row showing the current currency. Tap to choose another.
class CurrencyTile extends StatelessWidget {
  const CurrencyTile({super.key});

  Future<void> _choose(BuildContext context, Currency current) async {
    final cubit = context.read<SettingsCubit>();
    final picked = await showCurrencySheet(context, selected: current);
    if (picked == null || picked == current) return;

    await cubit.setCurrency(picked);
    if (context.mounted) {
      context.showInfo(
        picked.symbol.isEmpty
            ? 'Amounts are shown as plain numbers.'
            : 'Amounts are shown in ${picked.name}. '
                  'Saved amounts are not converted.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = context.select<SettingsCubit, Currency>(
      (cubit) => cubit.state.currency,
    );
    return ListTile(
      leading: const Icon(Icons.payments_outlined),
      title: const Text('Currency'),
      subtitle: Text(currency.label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _choose(context, currency),
    );
  }
}
