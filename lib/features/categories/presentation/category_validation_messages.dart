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
