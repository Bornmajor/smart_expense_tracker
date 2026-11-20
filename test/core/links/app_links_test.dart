import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/links/app_links.dart';

void main() {
  Uri? uriFor(String url) => AppLinks(privacyPolicyUrl: url).privacyPolicyUri;

  test('has no privacy policy address until one is set', () {
    expect(const AppLinks(privacyPolicyUrl: '').privacyPolicyUri, isNull);
  });

  test('accepts a secure web address', () {
    expect(
      uriFor('https://sites.google.com/view/spendwise-iq-privacy'),
      Uri.parse('https://sites.google.com/view/spendwise-iq-privacy'),
    );
  });

  test('ignores spaces around the address', () {
    expect(uriFor('  https://example.com/privacy \n'), isNotNull);
  });

  test('refuses an address that is not secure', () {
    expect(uriFor('http://example.com/privacy'), isNull);
  });

  test('refuses other kinds of link', () {
    expect(uriFor('javascript:alert(1)'), isNull);
    expect(uriFor('file:///etc/passwd'), isNull);
    expect(uriFor('intent://example#Intent;end'), isNull);
  });

  test('refuses text that is not an address', () {
    expect(uriFor('not a url'), isNull);
    expect(uriFor('https://'), isNull);
  });

  test('the address in the app is empty or a secure web address', () {
    // Empty is allowed so the Settings row stays hidden until it is set; see
    // docs/release-checklist.md. Anything else must be a usable address.
    const links = AppLinks();

    expect(
      links.privacyPolicyUrl.isEmpty || links.privacyPolicyUri != null,
      isTrue,
    );
  });
}
