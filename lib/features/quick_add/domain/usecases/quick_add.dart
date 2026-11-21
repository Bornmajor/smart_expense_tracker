import '../../../../core/errors/storage_exception.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../../expenses/domain/usecases/vendor_category_memory.dart';
import '../../../scan/domain/usecases/suggest_category.dart';
import '../entities/quick_add_result.dart';
import 'parse_quick_add.dart';

/// Turns a typed line into a filled-in expense form: the amount, date, vendor
/// and title from the words, and a category the user has used for this vendor
/// before, or one the words point to. It only suggests; nothing is saved until
/// the user checks the form and presses Save.
class QuickAdd {
  QuickAdd({
    required this._categories,
    required this._memory,
    ParseQuickAdd? parse,
    this._suggest = const SuggestCategory(),
  }) : _parse = parse ?? ParseQuickAdd();

  final CategoryRepository _categories;
  final VendorCategoryMemory _memory;
  final ParseQuickAdd _parse;
  final SuggestCategory _suggest;

  Future<QuickAddResult> call(String text) async {
    final draft = _parse(text);
    final availableIds = await _categoryIds();

    // What the user did with this vendor before beats a guess from words.
    final remembered = await _memory.categoryFor(
      draft.vendor,
      availableIds: availableIds,
    );

    return QuickAddResult(
      text: text.trim(),
      draft: draft,
      suggestedCategoryId:
          remembered ??
          _suggest(
            vendor: draft.vendor,
            lines: [if (draft.title.isNotEmpty) draft.title],
            availableIds: availableIds,
          ),
      categoryFromHistory: remembered != null,
    );
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
