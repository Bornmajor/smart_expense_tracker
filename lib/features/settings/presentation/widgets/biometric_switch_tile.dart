import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../security/presentation/cubit/security_cubit.dart';
import '../../../security/presentation/cubit/security_state.dart';

/// Switch for the biometric lock, with snackbar feedback for each outcome.
class BiometricSwitchTile extends StatelessWidget {
  const BiometricSwitchTile({super.key});

  static String message(SecurityFeedback feedback) => switch (feedback) {
    SecurityFeedback.turnedOn => 'Biometric lock turned on',
    SecurityFeedback.turnedOff => 'Biometric lock turned off',
    SecurityFeedback.unavailable =>
      'Set up a fingerprint or face unlock on this device first',
    SecurityFeedback.failed => 'Couldn\'t verify it\'s you. Try again.',
  };

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SecurityCubit, SecurityState>(
      listenWhen: (previous, current) =>
          current.feedback != null && current.attempt != previous.attempt,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message(state.feedback!))));
      },
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
