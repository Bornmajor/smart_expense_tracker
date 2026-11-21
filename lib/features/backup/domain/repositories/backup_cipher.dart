import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// A backup after it was locked with a password.
class EncryptedPayload extends Equatable {
  const EncryptedPayload({
    required this.iterations,
    required this.salt,
    required this.nonce,
    required this.cipherText,
    required this.mac,
  });

  /// How many rounds turned the password into the key. Kept in the file so it
  /// can be raised later and old backups still open.
  final int iterations;
  final Uint8List salt;
  final Uint8List nonce;
  final Uint8List cipherText;
  final Uint8List mac;

  @override
  List<Object?> get props => [iterations, salt, nonce, cipherText, mac];
}

/// Locks and unlocks backup contents with a password.
abstract interface class BackupCipher {
  Future<EncryptedPayload> encrypt(Uint8List plain, String password);

  /// Throws `BackupException` (wrongPassword) when the password does not open
  /// it, or the contents were changed.
  Future<Uint8List> decrypt(EncryptedPayload payload, String password);
}
