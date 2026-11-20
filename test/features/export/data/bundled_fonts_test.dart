import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/export/data/writers/bundled_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads both Inter files that ship with the app', () async {
    final fonts = await loadBundledFonts();

    // A TrueType file starts with these four bytes.
    expect(fonts.regular.take(4), [0, 1, 0, 0]);
    expect(fonts.bold.take(4), [0, 1, 0, 0]);
    expect(fonts.regular.length, greaterThan(100000));
    expect(fonts.bold.length, greaterThan(100000));
  });
}
