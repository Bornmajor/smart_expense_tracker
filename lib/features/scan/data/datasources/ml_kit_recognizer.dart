// coverage:ignore-file
// The only code that calls ML Kit. It needs a real device, so it stays as
// small as possible and the logic around it is tested with a fake.
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Reads the text in the photo with ML Kit, on the device.
Future<RecognizedText> recognizeWithMlKit(String photoPath) async {
  final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  try {
    return await recognizer.processImage(InputImage.fromFilePath(photoPath));
  } finally {
    await recognizer.close();
  }
}
