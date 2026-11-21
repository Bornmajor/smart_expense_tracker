import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../../../core/errors/app_failure.dart';
import '../../domain/backup_exception.dart';
import '../../domain/repositories/backup_cipher.dart';

/// Locks a backup with a password: the key comes from the password with
/// PBKDF2 (HMAC-SHA256), and the content is sealed with AES-256-GCM, which
/// also detects a wrong password or a changed file.
class CryptographyBackupCipher implements BackupCipher {
  /// [iterations] is only lowered in tests. Many rounds make guessing a
  /// password slow, and the number is saved in the file.
  CryptographyBackupCipher({this.iterations = defaultIterations});

  static const defaultIterations = 120000;

  final int iterations;

  static final _aes = AesGcm.with256bits();

  @override
  Future<EncryptedPayload> encrypt(Uint8List plain, String password) async {
    final salt = _randomBytes(16);
    final key = await _key(password, salt, iterations);
    final box = await _aes.encrypt(
      plain,
      secretKey: SecretKey(key),
      nonce: _aes.newNonce(),
    );
    return EncryptedPayload(
      iterations: iterations,
      salt: salt,
      nonce: Uint8List.fromList(box.nonce),
      cipherText: Uint8List.fromList(box.cipherText),
      mac: Uint8List.fromList(box.mac.bytes),
    );
  }

  @override
  Future<Uint8List> decrypt(EncryptedPayload payload, String password) async {
    final key = await _key(password, payload.salt, payload.iterations);
    try {
      final plain = await _aes.decrypt(
        SecretBox(
          payload.cipherText,
          nonce: payload.nonce,
          mac: Mac(payload.mac),
        ),
        secretKey: SecretKey(key),
      );
      return Uint8List.fromList(plain);
    } on SecretBoxAuthenticationError {
      throw const BackupException(BackupProblem.wrongPassword);
    }
  }

  /// Derived off the main thread: thousands of rounds would freeze the screen.
  Future<List<int>> _key(String password, List<int> salt, int rounds) {
    return Isolate.run(() async {
      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: rounds,
        bits: 256,
      );
      final key = await pbkdf2.deriveKeyFromPassword(
        password: password,
        nonce: salt,
      );
      return key.extractBytes();
    });
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList([
      for (var i = 0; i < length; i++) random.nextInt(256),
    ]);
  }
}
