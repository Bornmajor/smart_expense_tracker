import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../../expenses/domain/usecases/vendor_category_memory.dart';
import '../entities/receipt_source.dart';
import '../entities/scan_result.dart';
import '../parsing/receipt_rows.dart';
import '../repositories/receipt_photo_source.dart';
import '../repositories/receipt_text_reader.dart';
import '../scan_exception.dart';
import 'parse_receipt.dart';
import 'suggest_category.dart';

/// The steps of scanning a receipt. They are separate, because the screen
/// stops in between: a photo from the camera is shown to the user first, who
/// either uses it or retakes it.
///
///  1. [pick] (or [recover] after the app was restarted) gives a photo path.
///  2. [read] reads the photo and works out the vendor, date, total and a
///     likely category, ready to fill in the expense form.
///  3. [discard] deletes a photo that will not be used.
class ScanReceipt {
  ScanReceipt({
    required this._photos,
    required this._reader,
    required this._categories,
    required this._memory,
    ParseReceipt? parse,
    this._suggest = const SuggestCategory(),
  }) : _parse = parse ?? ParseReceipt();

  final ReceiptPhotoSource _photos;
  final ReceiptTextReader _reader;
  final CategoryRepository _categories;
  final VendorCategoryMemory _memory;
  final ParseReceipt _parse;
  final SuggestCategory _suggest;

  /// Takes a photo with the camera, or picks a photo or PDF file.
  /// Returns null when the user backs out without choosing one.
  Future<Result<String>?> pick(ReceiptSource source) async {
    try {
      final path = await _photos.pick(source);
      return path == null ? null : Success(path);
    } on ScanException catch (e) {
      return Failure(ScanFailure(e.problem));
    }
  }

  /// The photo taken just before Android restarted the app, or null. It can
  /// be recovered once.
  Future<String?> recover() => _photos.recoverLost();

  /// Reads the photo. If that fails, the photo is deleted, since nothing will
  /// show it. On success it stays, because the form shows it beside the fields.
  Future<Result<ScanResult>> read(String photoPath) async {
    try {
      final lines = ReceiptRows.build(await _reader.read(photoPath));
      final draft = _parse(lines);
      final availableIds = await _categoryIds();

      // What the user did with this vendor before beats a guess from words.
      final remembered = await _memory.categoryFor(
        draft.vendor,
        availableIds: availableIds,
      );

      return Success(
        ScanResult(
          photoPath: photoPath,
          draft: draft,
          suggestedCategoryId:
              remembered ??
              _suggest(
                vendor: draft.vendor,
                lines: lines,
                availableIds: availableIds,
              ),
          categoryFromHistory: remembered != null,
        ),
      );
    } on ScanException catch (e) {
      await _photos.discard(photoPath);
      return Failure(ScanFailure(e.problem));
    } catch (_) {
      // An unexpected bug. It is not hidden (it is rethrown), but the photo
      // still does not stay behind.
      await _photos.discard(photoPath);
      rethrow;
    }
  }

  /// Deletes a photo that will not be used, such as one the user retook.
  Future<void> discard(String photoPath) => _photos.discard(photoPath);

  /// The categories the user has. Without them there is simply no suggestion.
  Future<Set<String>> _categoryIds() async {
    try {
      return {for (final c in await _categories.getAll()) c.id};
    } on StorageException {
      return {};
    }
  }
}
