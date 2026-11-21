import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/info/app_version.dart';

void main() {
  test('writes the name with the build number', () {
    expect(
      const AppVersion(name: '1.0.0', build: '12').label,
      '1.0.0 (build 12)',
    );
  });

  test('writes just the name when there is no build number', () {
    expect(const AppVersion(name: '1.0.0-dev', build: '').label, '1.0.0-dev');
  });

  test('has no label while the version is not known', () {
    expect(AppVersion.unknown.label, isNull);
  });
}
