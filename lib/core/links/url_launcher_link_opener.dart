// coverage:ignore-file
// The only code that calls url_launcher. It needs a real phone, so it stays as
// small as possible and everything around it is tested with a fake.
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'link_opener.dart';

class UrlLauncherLinkOpener implements LinkOpener {
  const UrlLauncherLinkOpener();

  @override
  Future<bool> open(Uri uri) async {
    try {
      // The browser, not a web view inside the app.
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException {
      return false;
    }
  }
}
