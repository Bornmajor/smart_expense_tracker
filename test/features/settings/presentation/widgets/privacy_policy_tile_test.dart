import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/links/app_links.dart';
import 'package:smart_expense_tracker/core/links/link_opener.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/features/settings/presentation/widgets/privacy_policy_tile.dart';

import '../../../../support/fakes.dart';

void main() {
  const address = 'https://example.com/privacy';

  Future<void> pumpTile(
    WidgetTester tester, {
    required String url,
    required FakeLinkOpener opener,
  }) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AppLinks>.value(
            value: AppLinks(privacyPolicyUrl: url),
          ),
          RepositoryProvider<LinkOpener>.value(value: opener),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: PrivacyPolicyTile()),
        ),
      ),
    );
  }

  testWidgets('shows the row when the address is set', (tester) async {
    await pumpTile(tester, url: address, opener: FakeLinkOpener());

    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('How your data is handled'), findsOneWidget);
  });

  testWidgets('is hidden, and takes no room, while no address is set', (
    tester,
  ) async {
    await pumpTile(tester, url: '', opener: FakeLinkOpener());

    expect(find.text('Privacy policy'), findsNothing);
    expect(tester.getSize(find.byType(PrivacyPolicyTile)), Size.zero);
  });

  testWidgets('is hidden for an address that is not secure', (tester) async {
    await pumpTile(
      tester,
      url: 'http://example.com/privacy',
      opener: FakeLinkOpener(),
    );

    expect(find.text('Privacy policy'), findsNothing);
  });

  testWidgets('opens the page when tapped', (tester) async {
    final opener = FakeLinkOpener();
    await pumpTile(tester, url: address, opener: opener);

    await tester.tap(find.text('Privacy policy'));
    await tester.pumpAndSettle();

    expect(opener.opened, [Uri.parse(address)]);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('tells the user when the page cannot be opened', (tester) async {
    final opener = FakeLinkOpener(succeeds: false);
    await pumpTile(tester, url: address, opener: opener);

    await tester.tap(find.text('Privacy policy'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Couldn\'t open the page'), findsOneWidget);
  });
}
