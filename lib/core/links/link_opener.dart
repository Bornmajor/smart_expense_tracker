/// Opens a web page in the phone's browser.
abstract interface class LinkOpener {
  /// Returns false when no app could open the page.
  Future<bool> open(Uri uri);
}
