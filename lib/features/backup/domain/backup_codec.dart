import 'dart:convert';
import 'dart:typed_data';

import '../../../core/errors/app_failure.dart';
import 'backup_exception.dart';
import 'entities/backup_data.dart';
import 'repositories/backup_cipher.dart';

/// Turns a backup into the bytes of a file and back. The file is JSON, so a
/// person can read it; with a password, the whole content is locked inside.
class BackupCodec {
  const BackupCodec(this._cipher);

  static const _format = 'spendwise-iq-backup';

  final BackupCipher _cipher;

  Future<Uint8List> encode(BackupData data, {String? password}) async {
    final inner = <String, Object?>{
      'createdAt': data.createdAt.millisecondsSinceEpoch,
      'currency': data.currencyCode,
      'categories': data.categories,
      'expenses': data.expenses,
      'budgets': data.budgets,
      'recurringRules': data.recurringRules,
    };

    final envelope = <String, Object?>{
      'format': _format,
      'version': data.version,
    };
    if (password != null && password.isNotEmpty) {
      final payload = await _cipher.encrypt(
        Uint8List.fromList(utf8.encode(jsonEncode(inner))),
        password,
      );
      envelope
        ..['encrypted'] = true
        ..['iterations'] = payload.iterations
        ..['salt'] = base64Encode(payload.salt)
        ..['nonce'] = base64Encode(payload.nonce)
        ..['cipherText'] = base64Encode(payload.cipherText)
        ..['mac'] = base64Encode(payload.mac);
    } else {
      envelope
        ..['encrypted'] = false
        ..addAll(inner);
    }
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  /// Whether the file needs a password. Throws `BackupException` when it is
  /// not a backup this app can open.
  bool isEncrypted(Uint8List bytes) => _envelope(bytes)['encrypted'] == true;

  /// Throws `BackupException`: notABackup, newerVersion, passwordRequired,
  /// wrongPassword or damaged.
  Future<BackupData> decode(Uint8List bytes, {String? password}) async {
    final envelope = _envelope(bytes);
    final version = envelope['version'] as int;

    var inner = envelope;
    if (envelope['encrypted'] == true) {
      if (password == null || password.isEmpty) {
        throw const BackupException(BackupProblem.passwordRequired);
      }
      final plain = await _cipher.decrypt(_payload(envelope), password);
      inner = _asMap(_parse(plain), BackupProblem.damaged);
    }

    try {
      return BackupData(
        version: version,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          inner['createdAt'] as int,
        ),
        currencyCode: inner['currency'] as String?,
        categories: _rows(inner['categories']),
        expenses: _rows(inner['expenses']),
        budgets: _rows(inner['budgets']),
        recurringRules: _rows(inner['recurringRules']),
      );
    } on BackupException {
      rethrow;
    } on Object {
      throw const BackupException(BackupProblem.damaged);
    }
  }

  Map<String, Object?> _envelope(Uint8List bytes) {
    final map = _asMap(_parse(bytes), BackupProblem.notABackup);
    if (map['format'] != _format || map['version'] is! int) {
      throw const BackupException(BackupProblem.notABackup);
    }
    if ((map['version'] as int) > BackupData.currentVersion) {
      throw const BackupException(BackupProblem.newerVersion);
    }
    return map;
  }

  Object? _parse(Uint8List bytes) {
    try {
      return jsonDecode(utf8.decode(bytes));
    } on Object {
      throw const BackupException(BackupProblem.notABackup);
    }
  }

  Map<String, Object?> _asMap(Object? value, BackupProblem otherwise) {
    if (value is Map) return Map<String, Object?>.from(value);
    throw BackupException(otherwise);
  }

  List<Map<String, Object?>> _rows(Object? value) {
    if (value is! List) throw const BackupException(BackupProblem.damaged);
    return [for (final row in value) _asMap(row, BackupProblem.damaged)];
  }

  EncryptedPayload _payload(Map<String, Object?> envelope) {
    try {
      return EncryptedPayload(
        iterations: envelope['iterations'] as int,
        salt: base64Decode(envelope['salt'] as String),
        nonce: base64Decode(envelope['nonce'] as String),
        cipherText: base64Decode(envelope['cipherText'] as String),
        mac: base64Decode(envelope['mac'] as String),
      );
    } on Object {
      throw const BackupException(BackupProblem.damaged);
    }
  }
}
