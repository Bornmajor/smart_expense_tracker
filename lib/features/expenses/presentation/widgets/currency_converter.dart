import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/money.dart';
import '../../../currency_conversion/domain/entities/exchange_rates.dart';
import '../../../currency_conversion/domain/usecases/convert_amount.dart';

/// The small "Different currency?" option under the amount. Closed, it is one
/// quiet link. Open, it names the other currency and shows what the amount
/// comes to in the app's currency, with the date of the rate used.
class CurrencyConverter extends StatelessWidget {
  const CurrencyConverter({
    super.key,
    required this.appCurrency,
    required this.from,
    required this.rates,
    required this.amountText,
    required this.onChoose,
    required this.onClear,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Rates older than this get a warning next to the date.
  static const staleAfter = Duration(days: 7);

  final Currency appCurrency;

  /// The other currency the amount is written in, or null when closed.
  final Currency? from;

  /// The downloaded rates, or null when none were ever downloaded.
  final ExchangeRates? rates;
  final String amountText;
  final VoidCallback onChoose;
  final VoidCallback onClear;
  final DateTime Function() _now;

  String? _result() {
    final other = from;
    final saved = rates;
    final minor = Money.tryParse(amountText);
    if (other == null || saved == null || minor == null) return null;
    final converted = ConvertAmount.call(
      minor: minor,
      from: other.code,
      to: appCurrency.code,
      rates: saved,
    );
    return converted == null ? null : '= ${appCurrency.format(converted)}';
  }

  String _note() {
    final saved = rates;
    final other = from;
    if (saved == null) {
      return 'Exchange rates are not downloaded yet. Connect to the '
          'internet once.';
    }
    if (other != null && !saved.has(other.code)) {
      return 'There is no rate for ${other.code}.';
    }
    final date = DateFormat('d MMM').format(saved.fetchedAt);
    return saved.isOlderThan(staleAfter, _now())
        ? 'Rate from $date, may be out of date'
        : 'Rate from $date';
  }

  @override
  Widget build(BuildContext context) {
    final other = from;
    if (other == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onChoose,
          icon: const Icon(Icons.currency_exchange, size: 18),
          label: const Text('Different currency?'),
        ),
      );
    }

    final result = _result();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActionChip(
            avatar: const Icon(Icons.currency_exchange, size: 16),
            label: Text(other.code),
            onPressed: onChoose,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result != null)
                  Text(result, style: context.text.titleMedium),
                Text(_note(), style: context.text.bodySmall),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Use ${appCurrency.code} instead',
            icon: const Icon(Icons.close),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}

/// Lists the currencies other than the app's own. Returns the one chosen, or
/// null when the sheet is closed without choosing.
Future<Currency?> showOtherCurrencySheet(
  BuildContext context, {
  required Currency appCurrency,
}) {
  final options = [
    for (final currency in Currency.all)
      if (currency.code.isNotEmpty && currency != appCurrency) currency,
  ];
  return showModalBottomSheet<Currency>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                0,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Text(
                'Amount is in',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final currency in options)
              ListTile(
                title: Text(currency.label),
                onTap: () => Navigator.pop(context, currency),
              ),
          ],
        ),
      ),
    ),
  );
}
