import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';

/// Bottom sheet listing the currencies. Returns the one chosen, or null when
/// the sheet is closed without choosing.
Future<Currency?> showCurrencySheet(
  BuildContext context, {
  required Currency selected,
}) {
  return showModalBottomSheet<Currency>(
    context: context,
    isScrollControlled: true,
    // Settings is a tab with its own navigator, which sits under the app's tab
    // bar. The root navigator puts the sheet above it.
    useRootNavigator: true,
    builder: (context) => _CurrencySheet(selected: selected),
  );
}

class _CurrencySheet extends StatelessWidget {
  const _CurrencySheet({required this.selected});

  final Currency selected;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        // One list for everything, title and note included, so on a small
        // phone with large text the whole sheet scrolls and nothing overflows.
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.xs,
              ),
              child: Text('Currency', style: context.text.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Text(
                'This changes how amounts are written. It does not convert '
                'the amounts you have already saved.',
                style: context.text.bodySmall,
              ),
            ),
            for (final currency in Currency.all)
              ListTile(
                selected: currency == selected,
                title: Text(currency.label),
                subtitle: currency.symbol.isEmpty
                    ? const Text('Amounts as plain numbers')
                    : Text('For example ${currency.format(123456)}'),
                trailing: currency == selected ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, currency),
              ),
          ],
        ),
      ),
    );
  }
}
