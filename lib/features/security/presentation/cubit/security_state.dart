import 'package:equatable/equatable.dart';

/// Result of the last switch change, shown to the user as a snackbar.
enum SecurityFeedback { turnedOn, turnedOff, unavailable, failed }

class SecurityState extends Equatable {
  const SecurityState({required this.enabled, this.feedback, this.attempt = 0});

  final bool enabled;
  final SecurityFeedback? feedback;

  /// Increases with every action, so repeating the same result still notifies.
  final int attempt;

  @override
  List<Object?> get props => [enabled, feedback, attempt];
}
