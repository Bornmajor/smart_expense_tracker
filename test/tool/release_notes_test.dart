import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_notes.dart';

void main() {
  const changelog = '''
# Changelog

Intro text.

## [Unreleased]

### Added

- A new thing

## [1.0.1] - 2026-12-01

### Fixed

- A bug

## [1.0.10] - 2026-12-20

- Tenth patch

## [1.0.0] - 2026-11-20

### Added

- First release
''';

  group('changelogSection', () {
    test('returns the section for the version', () {
      expect(changelogSection(changelog, '1.0.0'), '''
### Added

- First release''');
    });

    test('stops at the next version heading', () {
      final section = changelogSection(changelog, '1.0.1');

      expect(section, contains('A bug'));
      expect(section, isNot(contains('Tenth patch')));
      expect(section, isNot(contains('First release')));
    });

    test('does not mix up 1.0.1 and 1.0.10', () {
      expect(changelogSection(changelog, '1.0.10'), '- Tenth patch');
    });

    test('falls back to Unreleased when the version has no section yet', () {
      final section = changelogSection(changelog, '2.0.0');

      expect(section, contains('A new thing'));
      expect(section, isNot(contains('A bug')));
    });

    test('reads a file with Windows line endings', () {
      final windows = changelog.replaceAll('\n', '\r\n');

      expect(changelogSection(windows, '1.0.1'), contains('A bug'));
      expect(changelogSection(windows, '1.0.1'), isNot(contains('\r')));
    });

    test(
      'is empty when there is neither a version nor an Unreleased section',
      () {
        expect(changelogSection('# Changelog\n', '1.0.0'), isEmpty);
      },
    );
  });

  group('releaseNotes', () {
    test('puts the changes first and the install steps after', () {
      final notes = releaseNotes(changelog, '1.0.0');

      expect(
        notes.indexOf('First release'),
        lessThan(notes.indexOf('## Install')),
      );
    });

    test('names the APK and its checksum file', () {
      final notes = releaseNotes(changelog, '1.0.0');

      expect(notes, contains('`spendwise-iq-1.0.0.apk`'));
      expect(notes, contains('`spendwise-iq-1.0.0.apk.sha256`'));
    });

    test('warns about installing over a Google Play copy', () {
      expect(releaseNotes(changelog, '1.0.0'), contains('Google Play'));
    });

    test('never has empty notes', () {
      final notes = releaseNotes('# Changelog\n', '1.2.3');

      expect(notes, startsWith('SpendWise IQ 1.2.3.'));
    });
  });

  test('the APK name matches what the workflow uploads', () {
    expect(apkFileName('1.2.3'), 'spendwise-iq-1.2.3.apk');
  });
}
