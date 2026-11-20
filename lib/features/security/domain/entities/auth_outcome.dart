/// How a check that the user is who they say they are ended.
enum AuthOutcome {
  /// The user was verified.
  success,

  /// The check ran and the user did not pass it, for example a wrong
  /// fingerprint. Trying again can work.
  failed,

  /// The user closed the prompt, or the system closed it (the app went to the
  /// background, for instance). Nothing is wrong, so nothing is shown.
  cancelled,

  /// Too many wrong tries. The phone blocks checks for a while.
  lockedOut,

  /// This phone cannot check the user right now: no screen lock or fingerprint
  /// is set up any more, or the check is broken on this device. Trying again
  /// will not help, so the lock screen must offer a way out.
  unavailable,
}
