/// Switches for parts of receipt scanning that are built but not offered yet.
abstract final class ScanFeatures {
  /// Taking a photo with the camera is switched off for now.
  ///
  /// On the Infinix test phone Android kills the app within seconds of the
  /// system camera opening, which looks like a crash. Choosing a photo from
  /// the gallery works very well, so that is the way to scan for now. The
  /// camera path, its preview and the recovery of the lost photo are all built
  /// and tested; see the camera item in docs/roadmap.md before turning this on.
  static const cameraEnabled = false;
}
