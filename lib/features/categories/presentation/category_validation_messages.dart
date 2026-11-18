import '../../../core/errors/app_failure.dart';
import '../domain/validation/category_rules.dart';

/// Turns a category error code into text for the user.
String categoryErrorMessage(String code) => switch (code) {
  CategoryError.nameRequired => 'Enter a name',
  CategoryError.nameTooLong =>
    'Names can have up to ${CategoryRules.maxNameLength} characters',
  CategoryError.nameTaken => 'You already have a category with this name',
  CategoryError.cannotDeleteFallback => 'This category receives expenses from deleted ones, so it can\'t be deleted',
  _ => 'Check the name',
};

/// What to show under the name field when saving a category did not work.
String categorySaveError(AppFailure failure) => switch (failure) {
  ValidationFailure(:final fieldErrors) => categoryErrorMessage(
    fieldErrors[CategoryField.name] ?? '',
  ),
  _ => 'Couldn\'t save the category. Try again.',
};
