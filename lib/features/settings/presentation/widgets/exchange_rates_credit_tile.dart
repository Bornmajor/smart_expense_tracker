import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/links/app_links.dart';
import '../../../../core/links/link_opener.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

/// The credit the exchange-rate service asks for, as a quiet Settings row.
class ExchangeRatesCreditTile extends StatelessWidget {
  const ExchangeRatesCreditTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.currency_exchange),
          title: const Text('Exchange rates'),
          subtitle: const Text('Rates by Exchange Rate API'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () async {
            final opened = await context.read<LinkOpener>().open(
              AppLinks.exchangeRatesUri,
            );
            if (!opened && context.mounted) {
              context.showError('Couldn\'t open the page. Try again later.');
            }
          },
        ),
      ),
    );
  }
}
