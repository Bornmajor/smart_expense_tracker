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

  test('the app has the published privacy policy address', () {
    // Google Play requires this link inside the app. If this fails, the address
    // was removed or broken: set it in lib/core/links/app_links.dart.
    final uri = const AppLinks().privacyPolicyUri;

    expect(uri, isNotNull);
    expect(
      uri.toString(),
      'https://sites.google.com/view/spendwiseiq-privacy-policy/home',
    );
  });
}
