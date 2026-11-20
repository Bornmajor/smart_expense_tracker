import 'package:equatable/equatable.dart';

/// The web pages the app links to.
class AppLinks extends Equatable {
  const AppLinks({this.privacyPolicyUrl = _privacyPolicyUrl});

  /// The published privacy policy page (Google Sites, public, no sign-in).
  ///
  /// Google Play requires a link to it inside the app as well as in the store
  /// listing. Paste the page address here when it is published. While this is
  /// empty the Settings row is hidden, so the app never opens a wrong page.
  /// See docs/release-checklist.md.
  static const _privacyPolicyUrl = '';

  final String privacyPolicyUrl;

  /// The privacy policy page, or null when it is not set or is not a secure
  /// web address. Only https is accepted.
  Uri? get privacyPolicyUri {
    final uri = Uri.tryParse(privacyPolicyUrl.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return uri;
  }

  @override
  List<Object?> get props => [privacyPolicyUrl];
}
