import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../entities/receipt_source.dart';
import '../entities/scan_result.dart';
import '../parsing/receipt_rows.dart';
import '../repositories/receipt_photo_source.dart';
import '../repositories/receipt_text_reader.dart';
import '../scan_exception.dart';
import 'parse_receipt.dart';
import 'suggest_category.dart';

/// Takes or picks a receipt photo, reads it, and works out the vendor, date,
/// total and a likely category, ready to fill in the expense form.
///
/// Returns null when the user backs out without choosing a photo. If the photo
/// cannot be read, it is deleted before a failure is returned.
class ScanReceipt {
  ScanReceipt({
    required this._photos,
    required this._reader,
    required this._categories,
    ParseReceipt? parse,
    this._suggest = const SuggestCategory(),
  }) : _parse = parse ?? ParseReceipt();

  final ReceiptPhotoSource _photos;
  final ReceiptTextReader _reader;
  final CategoryRepository _categories;
  final ParseReceipt _parse;
  final SuggestCategory _suggest;

  Future<Result<ScanResult>?> call(ReceiptSource source) async {
    final String? path;
    try {
      path = await _photos.pick(source);
    } on ScanException catch (e) {
      return Failure(ScanFailure(e.problem));
    }
    if (path == null) return null;

    try {
      final lines = ReceiptRows.build(await _reader.read(path));
      final draft = _parse(lines);

      return Success(
        ScanResult(
          photoPath: path,
          draft: draft,
          suggestedCategoryId: _suggest(
            vendor: draft.vendor,
            lines: lines,
            availableIds: await _categoryIds(),
          ),
        ),
      );
    } on ScanException catch (e) {
      // Nothing will show this photo, so it does not stay on the device.
      await _photos.discard(path);
      return Failure(ScanFailure(e.problem));
    } catch (_) {
      // An unexpected bug. It is not hidden (it is rethrown), but the photo
      // still does not stay behind.
      await _photos.discard(path);
      rethrow;
    }
  }

  /// The categories the user has. Without them there is simply no suggestion.
  Future<Set<String>> _categoryIds() async {
    try {
      return {for (final c in await _categories.getAll()) c.id};
    } on StorageException {
      return {};
    }
  }
}
