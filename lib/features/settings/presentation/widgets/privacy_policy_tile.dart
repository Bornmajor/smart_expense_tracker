import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/links/app_links.dart';
import '../../../../core/links/link_opener.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

/// A Settings row that opens the privacy policy page in the browser.
/// It is not shown until the page address is set in [AppLinks].
class PrivacyPolicyTile extends StatelessWidget {
  const PrivacyPolicyTile({super.key});

  @override
  Widget build(BuildContext context) {
    final uri = context.read<AppLinks>().privacyPolicyUri;
    if (uri == null) return const SizedBox.shrink();

    // Its own spacing, so nothing is left behind while the row is hidden.
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy policy'),
          subtitle: const Text('How your data is handled'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _open(context, uri),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = await context.read<LinkOpener>().open(uri);
    if (!opened && context.mounted) {
      context.showError(
        'Couldn\'t open the page. Check your connection and try again.',
      );
    }
  }
}
