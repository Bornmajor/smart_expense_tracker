import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../cubit/lock_cubit.dart';
import '../cubit/lock_state.dart';
import '../cubit/security_cubit.dart';

/// Shown on launch (and after returning from a long break) when the
/// app lock is on.
///
/// The lock must never leave someone unable to use their own app. When the
/// phone can no longer check the user (the screen lock was removed, or the
/// check is broken on this phone), this screen explains it and offers to turn
/// the lock off.
class LockPage extends StatefulWidget {
  const LockPage({super.key});

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  @override
  void initState() {
    super.initState();
    // Ask straight away, so the user does not have to tap first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LockCubit>().authenticate();
    });
  }

  Future<void> _confirmTurnOff() async {
    final security = context.read<SecurityCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Turn off the app lock?'),
        content: const Text(
          'Anyone who opens your phone will be able to open SpendWise IQ. '
          'You can turn the lock on again in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Turn off'),
          ),
        ],
      ),
    );
    if (confirmed == true) await security.setBiometricEnabled(false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LockCubit, LockScreenState>(
      listenWhen: (previous, current) =>
          current.status == LockStatus.failed ||
          current.status == LockStatus.lockedOut,
      listener: (context, state) {
        if (state.status == LockStatus.lockedOut) {
          context.showWarning('Too many tries. Wait a moment, then try again.');
        } else {
          context.showError('Couldn\'t verify it\'s you. Try again.');
        }
      },
      builder: (context, state) {
        final busy = state.status == LockStatus.authenticating;
        final unavailable = state.status == LockStatus.unavailable;
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const AppLogo(size: 88),
                  const Gap(AppSpacing.xl),
                  Text(
                    'SpendWise IQ is locked',
                    textAlign: TextAlign.center,
                    style: context.text.headlineMedium,
                  ),
                  const Gap(AppSpacing.md),
                  Text(
                    unavailable
                        ? 'This phone can\'t check it\'s you right now. It may '
                              'no longer have a screen lock, fingerprint or '
                              'face set up.'
                        : 'Use your fingerprint, face or phone screen lock to '
                              'continue.',
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium,
                  ),
                  const Gap(AppSpacing.xxl),
                  // Kept near the middle so the snackbar never covers it.
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => context.read<LockCubit>().authenticate(),
                    icon: const Icon(Icons.fingerprint),
                    label: Text(unavailable ? 'Try again' : 'Unlock'),
                  ),
                  if (unavailable) ...[
                    const Gap(AppSpacing.md),
                    OutlinedButton(
                      onPressed: _confirmTurnOff,
                      child: const Text('Turn off app lock'),
                    ),
                  ],
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
