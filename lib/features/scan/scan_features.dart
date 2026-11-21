/// Switches for parts of receipt scanning that can be turned off.
abstract final class ScanFeatures {
  /// Taking a photo with the camera.
  ///
  /// Turned on to test it in a release build. On the Infinix test phone
  /// Android killed the app within seconds of the system camera opening in a
  /// debug build, which looked like a crash; the camera path, its preview and
  /// the recovery of the lost photo are built for that case. If it still fails
  /// in release, set this back to false and see the camera item in
  /// docs/roadmap.md.
  static const cameraEnabled = true;
}
