import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/debug/test_clock.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/section_header.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../widgets/biometric_switch_tile.dart';
import '../widgets/currency_tile.dart';
import '../widgets/exchange_rates_credit_tile.dart';
import '../widgets/privacy_policy_tile.dart';
import '../widgets/test_date_tile.dart';
import '../widgets/theme_mode_selector.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: AppSpacing.screen.copyWith(bottom: AppSpacing.xxl),
        children: [
          const SectionHeader('Appearance'),
          Card(
            child: Padding(
              padding: AppSpacing.card,
              child: BlocBuilder<SettingsCubit, SettingsState>(
                builder: (context, state) => SizedBox(
                  width: double.infinity,
                  child: ThemeModeSelector(
                    selected: state.themeMode,
                    onChanged: context.read<SettingsCubit>().setThemeMode,
                  ),
                ),
              ),
            ),
          ),
          const Gap(AppSpacing.xl),
          const SectionHeader('Spending'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Categories'),
                  subtitle: const Text('Add, rename or delete categories'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.categories),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.savings_outlined),
                  title: const Text('Budgets'),
                  subtitle: const Text('Set monthly spending limits'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.budgets),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.repeat),
                  title: const Text('Recurring expenses'),
                  subtitle: const Text(
                    'Rent, subscriptions and bills that repeat',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.recurring),
                ),
                const Divider(),
                const CurrencyTile(),
              ],
            ),
          ),
          const Gap(AppSpacing.xl),
          const SectionHeader('Security'),
          const Card(child: BiometricSwitchTile()),
          const Gap(AppSpacing.xl),
          const SectionHeader('About'),
          Card(
            child: ListTile(
              leading: const AppLogo(size: 36),
              title: const Text('SpendWise IQ'),
              subtitle: const Text('Your data stays on this device'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'SpendWise IQ',
                applicationIcon: const AppLogo(size: 48),
                children: const [
                  Text(
                    'Scan or type your expenses and see where your money goes. '
                    'Everything is stored on your phone and works offline.',
                  ),
                ],
              ),
            ),
          ),
          const PrivacyPolicyTile(),
          const ExchangeRatesCreditTile(),
          // TEMPORARY developer tools, only in debug builds and the dev flavor.
          if (developerToolsEnabled) ...[
            const Gap(AppSpacing.xl),
            const SectionHeader('Developer'),
            const TestDateTile(),
          ],
          if (kDebugMode) ...[
            const Gap(AppSpacing.md),
            Card(
              child: ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('OCR test'),
                subtitle: const Text('Temporary: see what the scanner reads'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.ocrDebug),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
