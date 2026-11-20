// Writes the text of a GitHub release: the CHANGELOG section for the version,
// followed by short install steps.
//
// Usage: dart run tool/release_notes.dart <version> <output file> [CHANGELOG.md]
//
// The release workflow runs this and passes the file to `gh release create`.
// CHANGELOG.md says to rename "Unreleased" to the version when a release goes
// out. If that has not been done yet, the Unreleased section is used instead,
// so a release never goes out with empty notes.
import 'dart:io';

/// The file name of the APK attached to the release for [version].
String apkFileName(String version) => 'spendwise-iq-$version.apk';

/// The lines under the changelog heading for [version], or under "Unreleased"
/// when the version has no heading of its own. Empty when neither exists.
String changelogSection(String changelog, String version) {
  final lines = changelog.split(RegExp(r'\r?\n'));

  int headingOf(String name) =>
      lines.indexWhere((l) => l.startsWith('## [$name]'));

  var start = headingOf(version);
  if (start < 0) start = headingOf('Unreleased');
  if (start < 0) return '';

  final body = <String>[];
  for (final line in lines.skip(start + 1)) {
    if (line.startsWith('## [')) break; // the next version
    body.add(line);
  }
  return body.join('\n').trim();
}

/// The full text of the release page.
String releaseNotes(String changelog, String version) {
  final changes = changelogSection(changelog, version);
  final apk = apkFileName(version);

  return '''
${changes.isEmpty ? 'SpendWise IQ $version.' : changes}

## Install on Android

1. Download `$apk` below, on your phone.
2. Open it. If Android asks, allow installs from your browser or file manager.
3. Optional: check the download against `$apk.sha256`.

This file is signed with a different key than the one Google Play uses. If you already installed SpendWise IQ from Google Play, Android will not update it from this file: keep using Google Play, or uninstall that copy first (which removes its data).
''';
}

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln(
      'Usage: dart run tool/release_notes.dart <version> <output file> '
      '[CHANGELOG.md]',
    );
    exit(64);
  }
  final changelog = args.length > 2 ? args[2] : 'CHANGELOG.md';
  // Written to a file, not printed: `dart run` can print its own lines (such
  // as "Running build hooks...") to the same output, which would end up in the
  // release text.
  File(args[1]).writeAsStringSync(
    releaseNotes(File(changelog).readAsStringSync(), args.first),
  );
}
