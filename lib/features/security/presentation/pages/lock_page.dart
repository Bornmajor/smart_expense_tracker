import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../cubit/lock_cubit.dart';
import '../cubit/lock_state.dart';

/// Shown on launch (and after returning from a long break) when the
/// biometric lock is on.
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LockCubit, LockScreenState>(
      listenWhen: (previous, current) => current.status == LockStatus.failed,
      listener: (context, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Couldn\'t verify it\'s you. Try again.'),
          ),
        );
      },
      builder: (context, state) {
        final busy = state.status == LockStatus.authenticating;
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
                    'Use your fingerprint or face to continue.',
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
                    label: const Text('Unlock'),
                  ),
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
