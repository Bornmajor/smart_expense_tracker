/// A receipt photo taken before Android closed the app to free memory. It is
/// handed to the scan screen so the user can carry on from the preview.
class RecoveredPhoto {
  const RecoveredPhoto(this.path);

  final String path;
}
