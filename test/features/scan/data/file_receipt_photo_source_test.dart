import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/errors/app_failure.dart';
import 'package:smart_expense_tracker/features/scan/data/datasources/file_chooser.dart';
import 'package:smart_expense_tracker/features/scan/data/datasources/pdf_page_renderer.dart';
import 'package:smart_expense_tracker/features/scan/data/repositories/file_receipt_photo_source.dart';
import 'package:smart_expense_tracker/features/scan/data/repositories/routing_receipt_photo_source.dart';
import 'package:smart_expense_tracker/features/scan/domain/entities/receipt_source.dart';
import 'package:smart_expense_tracker/features/scan/domain/repositories/receipt_photo_source.dart';
import 'package:smart_expense_tracker/features/scan/domain/scan_exception.dart';

class FakeChooser implements FileChooser {
  String? path;
  Exception? error;

  @override
  Future<String?> chooseFile() async {
    if (error != null) throw error!;
    return path;
  }
}

class FakeRenderer implements PdfPageRenderer {
  bool fail = false;
  String? renderedFrom;

  @override
  Future<void> renderFirstPage(String pdfPath, String imagePath) async {
    renderedFrom = pdfPath;
    await File(imagePath).writeAsString('png');
    if (fail) throw const PdfRenderException('bad pdf');
  }
}

class RecordingSource implements ReceiptPhotoSource {
  final calls = <String>[];

  @override
  Future<String?> pick(ReceiptSource source) async {
    calls.add('pick ${source.name}');
    return '/x.jpg';
  }

  @override
  Future<String?> recoverLost() async {
    calls.add('recover');
    return null;
  }

  @override
  Future<void> discard(String path) async => calls.add('discard $path');
}

void main() {
  late Directory temp;
  late Directory user;
  late FakeChooser chooser;
  late FakeRenderer renderer;
  late FileReceiptPhotoSource source;

  File chosen(String name, List<int> bytes, {required Directory location}) =>
      File('${location.path}/$name')..writeAsBytesSync(bytes);

  setUp(() {
    temp = Directory.systemTemp.createTempSync('app_cache');
    user = Directory.systemTemp.createTempSync('user_files');
    chooser = FakeChooser();
    renderer = FakeRenderer();
    var n = 0;
    source = FileReceiptPhotoSource(
      chooser: chooser,
      renderer: renderer,
      tempDirectory: temp,
      newName: () => '${n++}',
    );
  });

  tearDown(() {
    temp.deleteSync(recursive: true);
    user.deleteSync(recursive: true);
  });

  Future<ScanProblem> failureOf() async {
    try {
      await source.pick(ReceiptSource.file);
    } on ScanException catch (e) {
      return e.problem;
    }
    fail('expected a ScanException');
  }

  group('FileReceiptPhotoSource.pick', () {
    test('returns null when the user backs out', () async {
      expect(await source.pick(ReceiptSource.file), isNull);
    });

    test('draws a PDF as an image and removes the Files app copy', () async {
      final pdf = chosen('r.pdf', '%PDF-1.4'.codeUnits, location: temp);
      chooser.path = pdf.path;

      final path = await source.pick(ReceiptSource.file);

      expect(renderer.renderedFrom, pdf.path);
      expect(path, endsWith('.png'));
      expect(File(path!).existsSync(), isTrue);
      expect(pdf.existsSync(), isFalse);
    });

    test('copies a photo to its own file', () async {
      final photo = chosen('p.jpg', [0xFF, 0xD8, 0xFF, 0xE0], location: temp);
      chooser.path = photo.path;

      final path = await source.pick(ReceiptSource.file);

      expect(File(path!).readAsBytesSync(), [0xFF, 0xD8, 0xFF, 0xE0]);
      expect(path, isNot(photo.path));
      expect(photo.existsSync(), isFalse);
    });

    test('never deletes a file outside the app cache', () async {
      final photo = chosen('mine.jpg', [
        0xFF,
        0xD8,
        0xFF,
        0xE0,
      ], location: user);
      chooser.path = photo.path;

      await source.pick(ReceiptSource.file);

      expect(photo.existsSync(), isTrue);
    });

    test('refuses a file that is not a photo or a PDF', () async {
      final doc = chosen('notes.txt', 'hello'.codeUnits, location: temp);
      chooser.path = doc.path;

      expect(await failureOf(), ScanProblem.unsupportedFile);
      expect(doc.existsSync(), isFalse);
    });

    test('a PDF that cannot be drawn leaves nothing behind', () async {
      final pdf = chosen('locked.pdf', '%PDF-1.4'.codeUnits, location: temp);
      chooser.path = pdf.path;
      renderer.fail = true;

      expect(await failureOf(), ScanProblem.cannotOpenFile);
      expect(temp.listSync(), isEmpty);
    });

    test('a file that has vanished cannot be opened', () async {
      chooser.path = '${temp.path}/gone.pdf';

      expect(await failureOf(), ScanProblem.cannotOpenFile);
    });

    test('passes on a failure to open the Files app', () async {
      chooser.error = const ScanException(ScanProblem.cannotOpenFile);

      expect(await failureOf(), ScanProblem.cannotOpenFile);
    });
  });

  group('FileReceiptPhotoSource.discard', () {
    test('deletes the image it made', () async {
      chooser.path = chosen('r.pdf', '%PDF-1.4'.codeUnits, location: temp).path;
      final path = (await source.pick(ReceiptSource.file))!;

      await source.discard(path);

      expect(File(path).existsSync(), isFalse);
    });

    test('leaves files it did not make alone', () async {
      final other = chosen('keep.jpg', [1, 2, 3], location: temp);
      final theirs = chosen('theirs.jpg', [1, 2, 3], location: user);

      await source.discard(other.path);
      await source.discard(theirs.path);

      expect(other.existsSync(), isTrue);
      expect(theirs.existsSync(), isTrue);
    });
  });

  group('RoutingReceiptPhotoSource', () {
    late RecordingSource camera;
    late RecordingSource file;
    late RoutingReceiptPhotoSource router;

    setUp(() {
      camera = RecordingSource();
      file = RecordingSource();
      router = RoutingReceiptPhotoSource(camera: camera, file: file);
    });

    test('sends each request to the right source', () async {
      await router.pick(ReceiptSource.camera);
      await router.pick(ReceiptSource.file);

      expect(camera.calls, ['pick camera']);
      expect(file.calls, ['pick file']);
    });

    test('recovers lost photos from the camera only', () async {
      await router.recoverLost();

      expect(camera.calls, ['recover']);
      expect(file.calls, isEmpty);
    });

    test('asks both sources to discard', () async {
      await router.discard('/a.png');

      expect(camera.calls, ['discard /a.png']);
      expect(file.calls, ['discard /a.png']);
    });
  });
}
