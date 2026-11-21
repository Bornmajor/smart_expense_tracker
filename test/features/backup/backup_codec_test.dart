import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/features/backup/data/crypto/cryptography_backup_cipher.dart';
import 'package:smart_expense_tracker/features/backup/domain/backup_codec.dart';
import 'package:smart_expense_tracker/features/backup/domain/backup_exception.dart';
import 'package:smart_expense_tracker/features/backup/domain/entities/backup_data.dart';

void main() {
  // A few rounds only: the tests do not need the real strength.
  final codec = BackupCodec(CryptographyBackupCipher(iterations: 2));

  final data = BackupData(
    version: BackupData.currentVersion,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1795000000000),
    currencyCode: 'KES',
    categories: const [
      {'id': 'food', 'name': 'Food'},
    ],
    expenses: const [
      {'id': 'e1', 'vendor': 'Naivas', 'amountMinor': 12345},
    ],
    budgets: const [
      {'scopeId': '*', 'limitMinor': 5000000},
    ],
    recurringRules: const [],
  );

  Future<BackupProblem> problemOf(Future<Object?> Function() action) async {
    try {
      await action();
    } on BackupException catch (e) {
      return e.problem;
    }
    fail('expected a BackupException');
  }

  Uint8List text(Object json) =>
      Uint8List.fromList(utf8.encode(jsonEncode(json)));

  group('a backup without a password', () {
    test('comes back exactly as it went in', () async {
      final bytes = await codec.encode(data);

      expect(await codec.decode(bytes), data);
      expect(codec.isEncrypted(bytes), isFalse);
    });

    test('is plain JSON a person can read', () async {
      final bytes = await codec.encode(data);

      expect(utf8.decode(bytes), contains('Naivas'));
    });

    test('a blank password means no password', () async {
      final bytes = await codec.encode(data, password: '');

      expect(codec.isEncrypted(bytes), isFalse);
    });
  });

  group('a backup with a password', () {
    test('comes back with the right password', () async {
      final bytes = await codec.encode(data, password: 'correct horse');

      expect(codec.isEncrypted(bytes), isTrue);
      expect(await codec.decode(bytes, password: 'correct horse'), data);
    });

    test('hides what is in it', () async {
      final bytes = await codec.encode(data, password: 'correct horse');

      expect(utf8.decode(bytes), isNot(contains('Naivas')));
    });

    test('asks for the password when none is given', () async {
      final bytes = await codec.encode(data, password: 'correct horse');

      expect(
        await problemOf(() => codec.decode(bytes)),
        BackupProblem.passwordRequired,
      );
    });

    test('refuses the wrong password', () async {
      final bytes = await codec.encode(data, password: 'correct horse');

      expect(
        await problemOf(() => codec.decode(bytes, password: 'wrong')),
        BackupProblem.wrongPassword,
      );
    });

    test('refuses a file that was changed', () async {
      final bytes = await codec.encode(data, password: 'correct horse');
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
      final cipher = base64Decode(json['cipherText'] as String);
      cipher[0] = cipher[0] ^ 0xFF;
      json['cipherText'] = base64Encode(cipher);

      expect(
        await problemOf(
          () => codec.decode(text(json), password: 'correct horse'),
        ),
        BackupProblem.wrongPassword,
      );
    });

    test('two backups of the same data are not the same bytes', () async {
      final a = await codec.encode(data, password: 'correct horse');
      final b = await codec.encode(data, password: 'correct horse');

      expect(a, isNot(b));
    });
  });

  group('a file that is not a good backup', () {
    test('is refused when it is not JSON', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4]);

      expect(
        await problemOf(() => codec.decode(bytes)),
        BackupProblem.notABackup,
      );
      expect(
        await problemOf(() async => codec.isEncrypted(bytes)),
        BackupProblem.notABackup,
      );
    });

    test('is refused when it is some other JSON', () async {
      expect(
        await problemOf(() => codec.decode(text({'hello': 'world'}))),
        BackupProblem.notABackup,
      );
      expect(
        await problemOf(() => codec.decode(text([1, 2]))),
        BackupProblem.notABackup,
      );
    });

    test('is refused when it comes from a newer version', () async {
      final json = jsonDecode(
        utf8.decode(await codec.encode(data)),
      ) as Map<String, Object?>;
      json['version'] = BackupData.currentVersion + 1;

      expect(
        await problemOf(() => codec.decode(text(json))),
        BackupProblem.newerVersion,
      );
    });

    test('is damaged when a list of rows is missing', () async {
      final json = jsonDecode(
        utf8.decode(await codec.encode(data)),
      ) as Map<String, Object?>;
      json.remove('expenses');

      expect(
        await problemOf(() => codec.decode(text(json))),
        BackupProblem.damaged,
      );
    });

    test('is damaged when a row is not an object', () async {
      final json = jsonDecode(
        utf8.decode(await codec.encode(data)),
      ) as Map<String, Object?>;
      json['expenses'] = [1, 2];

      expect(
        await problemOf(() => codec.decode(text(json))),
        BackupProblem.damaged,
      );
    });

    test('is damaged when the date is missing', () async {
      final json = jsonDecode(
        utf8.decode(await codec.encode(data)),
      ) as Map<String, Object?>;
      json.remove('createdAt');

      expect(
        await problemOf(() => codec.decode(text(json))),
        BackupProblem.damaged,
      );
    });
  });
}
