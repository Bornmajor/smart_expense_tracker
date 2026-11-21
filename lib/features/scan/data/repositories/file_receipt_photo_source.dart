import 'dart:io';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/receipt_file_kind.dart';
import '../../domain/entities/receipt_source.dart';
import '../../domain/repositories/receipt_photo_source.dart';
import '../../domain/scan_exception.dart';
import '../datasources/file_chooser.dart';
import '../datasources/pdf_page_renderer.dart';

/// Gets a receipt from a file the user picks in the phone's Files app: a
/// photo, a screenshot or a PDF.
///
/// Whatever the file is, what comes out is always an image of the receipt, so
/// the rest of scanning does not care. A PDF is drawn as an image of its first
/// page. The image is a temporary file of this app's own, deleted by
/// [discard] when the form closes, and the Files app's temporary copy is
/// deleted straight away. The user's own file is never touched.
class FileReceiptPhotoSource implements ReceiptPhotoSource {
  /// [tempDirectory] is where this app's temporary files go. It is the app's
  /// cache folder, which is also where the Files app puts its copies.
  FileReceiptPhotoSource({
    required this._chooser,
    required this._renderer,
    Directory? tempDirectory,
    String Function()? newName,
  }) : _tempDirectory = tempDirectory ?? Directory.systemTemp,
       _newName = newName ?? _timestampName;

  /// Every file this source makes starts with this, so [discard] only ever
  /// deletes its own.
  static const filePrefix = 'spendwise_receipt_';

  final FileChooser _chooser;
  final PdfPageRenderer _renderer;
  final Directory _tempDirectory;
  final String Function() _newName;

  static var _counter = 0;
  static String _timestampName() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_counter++}';

  @override
  Future<String?> pick(ReceiptSource source) async {
    assert(source == ReceiptSource.file, 'This source only picks files');

    // Left behind if Android closes the app while the Files app is open, so the
    // next start knows the choice was lost.
    await _writeMarker();
    final String? chosen;
    try {
      chosen = await _chooser.chooseFile();
    } finally {
      await _delete(_markerPath);
    }
    if (chosen == null) return null;

    try {
      final kind = ReceiptFileKind.detect(await _readHead(chosen));
      switch (kind) {
        case ReceiptFileKind.pdf:
          return await _renderPdf(chosen);
        case ReceiptFileKind.image:
          return await _copyImage(chosen);
        case ReceiptFileKind.unknown:
          throw const ScanException(ScanProblem.unsupportedFile);
      }
    } finally {
      await _deleteCopy(chosen);
    }
  }

  @override
  Future<String?> recoverLost() async => null;

  @override
  Future<bool> pickWasInterrupted() async {
    final marker = File(_markerPath);
    try {
      if (!await marker.exists()) return false;
      await marker.delete();
      return true;
    } on Exception {
      return false;
    }
  }

  @override
  Future<void> discard(String path) async {
    if (!_isOwn(path)) return;
    await _delete(path);
  }

  String get _markerPath =>
      '${_tempDirectory.path}${Platform.pathSeparator}spendwise_picking_file';

  Future<void> _writeMarker() async {
    try {
      await File(_markerPath).writeAsString('');
    } on Exception {
      // Only a courtesy message depends on it, so carry on without.
    }
  }

  /// The first bytes of the file, enough to tell what it is.
  Future<List<int>> _readHead(String path) async {
    try {
      final file = await File(path).open();
      try {
        return await file.read(ReceiptFileKind.headBytes);
      } finally {
        await file.close();
      }
    } on FileSystemException catch (e) {
      throw ScanException(ScanProblem.cannotOpenFile, e);
    }
  }

  Future<String> _renderPdf(String pdfPath) async {
    final imagePath = _newPath('png');
    try {
      await _renderer.renderFirstPage(pdfPath, imagePath);
      return imagePath;
    } on PdfRenderException catch (e) {
      await _delete(imagePath);
      throw ScanException(ScanProblem.cannotOpenFile, e);
    } on FileSystemException catch (e) {
      await _delete(imagePath);
      throw ScanException(ScanProblem.cannotOpenFile, e);
    }
  }

  Future<String> _copyImage(String sourcePath) async {
    final imagePath = _newPath('img');
    try {
      await File(sourcePath).copy(imagePath);
      return imagePath;
    } on FileSystemException catch (e) {
      await _delete(imagePath);
      throw ScanException(ScanProblem.cannotOpenFile, e);
    }
  }

  String _newPath(String extension) =>
      '${_tempDirectory.path}${Platform.pathSeparator}'
      '$filePrefix${_newName()}.$extension';

  /// True for a file this source made: in its temporary folder, with its
  /// prefix.
  bool _isOwn(String path) {
    final file = File(path);
    final name = file.uri.pathSegments.last;
    return name.startsWith(filePrefix) &&
        file.parent.absolute.path == _tempDirectory.absolute.path;
  }

  /// Deletes the Files app's copy, but only when it is in this app's temporary
  /// folder. A path anywhere else could be the user's own file, which must
  /// never be deleted.
  Future<void> _deleteCopy(String path) async {
    final file = File(path);
    final inTemp =
        file.parent.absolute.path == _tempDirectory.absolute.path ||
        file.absolute.path.startsWith(
          '${_tempDirectory.absolute.path}${Platform.pathSeparator}',
        );
    if (inTemp) await _delete(path);
  }

  Future<void> _delete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on Exception {
      // Already gone. Nothing to do.
    }
  }
}
