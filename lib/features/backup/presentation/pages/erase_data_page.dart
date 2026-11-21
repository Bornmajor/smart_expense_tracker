import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_routes.dart';
import '../../../../app/restart_widget.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/color_contrast.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../cubit/erase_data_cubit.dart';

/// Delete everything the user entered, after a clear warning, a reminder to
/// back up first, and typing a word to confirm.
class EraseDataPage extends StatefulWidget {
  const EraseDataPage({super.key});

  /// The word to type before the button works.
  static const confirmWord = 'DELETE';

  @override
  State<EraseDataPage> createState() => _EraseDataPageState();
}

class _EraseDataPageState extends State<EraseDataPage> {
  final _word = TextEditingController();

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  bool get _confirmed =>
      _word.text.trim().toUpperCase() == EraseDataPage.confirmWord;

  void _onState(BuildContext context, EraseDataState state) {
    switch (state.status) {
      case EraseStatus.done:
        // Start the whole app again, so it comes back as a fresh install: the
        // welcome screen, the standard settings and nothing remembered. Without
        // anything to restart (in a test), just leave this screen.
        if (!RestartWidget.restart(context)) context.go(AppRoutes.welcome);
      case EraseStatus.failed:
        context.showError(
          'Something went wrong. Your data was not changed. Please try again.',
        );
        context.read<EraseDataCubit>().acknowledgeFailure();
      case EraseStatus.idle || EraseStatus.working:
        break;
    }
  }

  String _lastBackup(DateTime? when) => when == null
      ? 'You have not made a backup yet.'
      : 'Your last backup file was made on '
            '${DateFormat.yMMMMd().format(when)}.';

  @override
  Widget build(BuildContext context) {
    final danger = context.semantic.danger;
    return BlocConsumer<EraseDataCubit, EraseDataState>(
      listener: _onState,
      builder: (context, state) {
        final busy = state.status == EraseStatus.working;
        return Scaffold(
          appBar: AppBar(title: const Text('Delete all my data')),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: AppSpacing.screen.copyWith(bottom: AppSpacing.xxl),
              children: [
                Icon(Icons.warning_amber_rounded, size: 40, color: danger),
                const Gap(AppSpacing.md),
                Text(
                  'This deletes everything and starts the app again as new.',
                  style: context.text.titleMedium,
                ),
                const Gap(AppSpacing.md),
                Text(
                  'Your expenses, recurring expenses, budgets and categories '
                  'will be removed, and the standard categories come back. '
                  'Your settings go back to the start too: the theme, the '
                  'currency and the app lock. You will see the welcome screen '
                  'again, as if you had just installed the app.\n\nThis can\'t '
                  'be undone. Nobody else has a copy, because the app keeps '
                  'everything only on your phone.',
                  style: context.text.bodyMedium,
                ),
                const Gap(AppSpacing.lg),
                Card(
                  child: Padding(
                    padding: AppSpacing.card,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Back up first?', style: context.text.titleSmall),
                        const Gap(AppSpacing.xs),
                        Text(
                          'A backup file lets you bring everything back later, '
                          'or move it to another phone. '
                          '${_lastBackup(state.lastBackupAt)}',
                          style: context.text.bodyMedium,
                        ),
                        const Gap(AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: busy
                              ? null
                              : () => context.push(AppRoutes.backup),
                          icon: const Icon(Icons.backup_outlined),
                          label: const Text('Back up now'),
                        ),
                      ],
                    ),
                  ),
                ),
                const Gap(AppSpacing.xl),
                Text(
                  'To go ahead, type ${EraseDataPage.confirmWord} below.',
                  style: context.text.bodyMedium,
                ),
                const Gap(AppSpacing.sm),
                TextField(
                  controller: _word,
                  enabled: !busy,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: EraseDataPage.confirmWord,
                  ),
                ),
                const Gap(AppSpacing.lg),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: danger,
                    foregroundColor: readableOn(danger),
                  ),
                  onPressed: busy || !_confirmed
                      ? null
                      : context.read<EraseDataCubit>().erase,
                  child: busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Delete everything'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
