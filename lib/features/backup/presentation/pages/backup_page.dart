import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../backup_messages.dart';
import '../cubit/backup_cubit.dart';
import '../cubit/backup_state.dart';

/// Back up everything to a file, or restore from one.
class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _protect = false;
  bool _tried = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? get _passwordProblem => _protect
      ? BackupPasswordRules.problem(_password.text, _confirm.text)
      : null;

  void _createBackup() {
    setState(() => _tried = true);
    if (_passwordProblem != null) return;
    context.read<BackupCubit>().createBackup(
      password: _protect ? _password.text : null,
    );
  }

  Future<void> _onState(BuildContext context, BackupState state) async {
    final cubit = context.read<BackupCubit>();
    switch (state) {
      case BackupCreated():
        context.showSuccess('Backup created. Keep the file somewhere safe.');
        _password.clear();
        _confirm.clear();
        setState(() {
          _protect = false;
          _tried = false;
        });
        cubit.reset();
      case RestoreNeedsPassword(:final wrongPassword):
        final password = await _askPassword(context, wrongPassword);
        if (password == null) {
          cubit.reset();
        } else {
          await cubit.openWithPassword(password);
        }
      case RestoreReady():
        final agreed = await _confirmRestore(context, state);
        if (agreed == true) {
          await cubit.confirmRestore();
        } else {
          cubit.reset();
        }
      case RestoreDone(:final currencyCode):
        final currency = Currency.byCode(currencyCode);
        if (currency != null) {
          await context.read<SettingsCubit>().setCurrency(currency);
        }
        if (context.mounted) context.showSuccess('Backup restored');
        cubit.reset();
      case BackupFailed(:final problem):
        context.showError(backupFailureMessage(problem));
        cubit.reset();
      case BackupIdle() || BackupWorking():
        break;
    }
  }

  Future<String?> _askPassword(BuildContext context, bool wrong) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Backup password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Password',
            errorText: wrong ? 'That password is not right' : null,
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Open'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<bool?> _confirmRestore(BuildContext context, RestoreReady backup) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Replace your data?'),
        content: SingleChildScrollView(
          child: Text(
            'This backup was made on '
            '${DateFormat.yMMMMd().format(backup.createdAt)}. It has '
            '${backup.expenses} expenses, ${backup.categories} categories, '
            '${backup.budgets} budgets and '
            '${backup.recurringRules} recurring expenses.\n\n'
            'Everything on this phone now will be removed and replaced by '
            'it. This can\'t be undone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BackupCubit, BackupState>(
      listener: _onState,
      builder: (context, state) {
        final busy = state is BackupWorking;
        final problem = _tried ? _passwordProblem : null;
        return Scaffold(
          appBar: AppBar(title: const Text('Back up and restore')),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: AppSpacing.screen.copyWith(bottom: AppSpacing.xxl),
              children: [
                const SectionHeader('Back up'),
                Text(
                  'Save everything in the app to one file: expenses, '
                  'categories, budgets and recurring expenses. Keep it '
                  'somewhere safe, such as Google Drive, to bring your data '
                  'back on a new phone. Nothing is uploaded by the app.',
                  style: context.text.bodyMedium,
                ),
                const Gap(AppSpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _protect,
                  onChanged: busy
                      ? null
                      : (value) => setState(() => _protect = value),
                  title: const Text('Protect with a password'),
                ),
                if (_protect) ...[
                  TextField(
                    controller: _password,
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const Gap(AppSpacing.md),
                  TextField(
                    controller: _confirm,
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Confirm password',
                      errorText: problem,
                    ),
                  ),
                  const Gap(AppSpacing.sm),
                  Text(
                    'If you forget the password, the backup can\'t be opened. '
                    'There is no way to recover it.',
                    style: context.text.bodySmall,
                  ),
                ],
                const Gap(AppSpacing.lg),
                FilledButton.icon(
                  onPressed: busy ? null : _createBackup,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Create backup'),
                ),
                const Gap(AppSpacing.xxl),
                const SectionHeader('Restore'),
                Text(
                  'Choose a backup file made by SpendWise IQ. You will see '
                  'what is in it before anything changes.',
                  style: context.text.bodyMedium,
                ),
                const Gap(AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : context.read<BackupCubit>().chooseFile,
                  icon: const Icon(Icons.restore),
                  label: const Text('Choose a backup file'),
                ),
                if (busy) ...[
                  const Gap(AppSpacing.xl),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
