import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../security/presentation/cubit/security_cubit.dart';
import '../../../security/presentation/cubit/security_state.dart';

/// Switch for the biometric lock, with snackbar feedback for each outcome.
class BiometricSwitchTile extends StatelessWidget {
  const BiometricSwitchTile({super.key});

  static void _announce(BuildContext context, SecurityFeedback feedback) {
    switch (feedback) {
      case SecurityFeedback.turnedOn:
        context.showSuccess('Biometric lock turned on');
      case SecurityFeedback.turnedOff:
        context.showInfo('Biometric lock turned off');
      case SecurityFeedback.unavailable:
        context.showWarning(
          'Set up a screen lock, fingerprint or face on this phone first',
        );
      case SecurityFeedback.failed:
        context.showError('Couldn\'t verify it\'s you. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SecurityCubit, SecurityState>(
      listenWhen: (previous, current) =>
          current.feedback != null && current.attempt != previous.attempt,
      listener: (context, state) => _announce(context, state.feedback!),
      builder: (context, state) => SwitchListTile(
        value: state.enabled,
        onChanged: context.read<SecurityCubit>().setBiometricEnabled,
        secondary: const Icon(Icons.fingerprint),
        title: const Text('Unlock with biometrics'),
        subtitle: const Text(
          'Ask for your fingerprint or face when you open the app',
        ),
      ),
    );
  }
}
