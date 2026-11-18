import '../entities/category.dart';

/// Field names used in category validation results.
abstract final class CategoryField {
  static const name = 'name';
}

/// Error codes. The UI maps these to user-facing text.
abstract final class CategoryError {
  static const nameRequired = 'name_required';
  static const nameTooLong = 'name_too_long';
  static const nameTaken = 'name_taken';
  static const cannotDeleteFallback = 'cannot_delete_fallback';
}

/// The rules for category names, shared by creating and renaming.
abstract final class CategoryRules {
  static const maxNameLength = 30;

  /// The name as it is stored: trimmed.
  static String cleanName(String name) => name.trim();

  /// Returns an error code, or null when the name is acceptable.
  ///
  /// A name is taken when another category already has it, ignoring case and
  /// the spaces around it. [exceptId] is the category being renamed, so keeping
  /// or re-casing its own name is fine.
  static String? validateName(
    String name,
    List<Category> existing, {
    String? exceptId,
  }) {
    final clean = cleanName(name);
    if (clean.isEmpty) return CategoryError.nameRequired;
    if (clean.length > maxNameLength) return CategoryError.nameTooLong;

    final lower = clean.toLowerCase();
    final taken = existing.any(
      (c) => c.id != exceptId && cleanName(c.name).toLowerCase() == lower,
    );
    return taken ? CategoryError.nameTaken : null;
  }
}
