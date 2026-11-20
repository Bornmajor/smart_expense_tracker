import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/storage_exception.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/recurrence_frequency.dart';
import '../../domain/entities/recurring_draft.dart';
import '../../domain/entities/recurring_rule.dart';
import '../../domain/repositories/recurring_repository.dart';
import '../../domain/usecases/generate_due_expenses.dart';
import '../../domain/usecases/save_recurring_rule.dart';
import 'recurring_form_state.dart';

/// Drives the form for a recurring rule. Without [original] it adds a rule;
/// with it, the form edits that rule and can delete it.
class RecurringFormCubit extends Cubit<RecurringFormState> {
  RecurringFormCubit({
    required this._saveRule,
    required this._repository,
    required this._generateDue,
    this.original,
  }) : super(const RecurringFormState());

  final SaveRecurringRule _saveRule;
  final RecurringRepository _repository;
  final GenerateDueExpenses _generateDue;
  final RecurringRule? original;

  bool get isEditing => original != null;

  Future<void> submit({
    String title = '',
    required String vendor,
    required String amountText,
    required String? categoryId,
    required RecurrenceFrequency frequency,
    required DateTime nextDue,
    bool isActive = true,
  }) async {
    if (state.busy) return;
    emit(const RecurringFormState(status: RecurringFormStatus.saving));

    // Turning text into a number is a form concern; the rules are in the use
    // case.
    final draft = RecurringDraft(
      title: title,
      vendor: vendor,
      amountMinor: Money.tryParse(amountText),
      categoryId: categoryId,
      frequency: frequency,
      nextDue: nextDue,
      isActive: isActive,
    );
    final result = await _saveRule(
      draft,
      original: original,
      amountText: amountText,
    );

    switch (result) {
      case Success():
        // A date that is already due adds its expense now, so the user sees it
        // straight away instead of at the next app start.
        final added = await _generateDue();
        emit(
          RecurringFormState(
            status: RecurringFormStatus.saved,
            addedCount: added,
          ),
        );
      case Failure(failure: final ValidationFailure validation):
        emit(
          RecurringFormState(
            status: RecurringFormStatus.editing,
            fieldErrors: validation.fieldErrors,
          ),
        );
      case Failure(:final failure):
        emit(
          RecurringFormState(
            status: RecurringFormStatus.failed,
            failure: failure,
          ),
        );
    }
  }

  /// Deletes the rule being edited. The expenses it already added stay. Does
  /// nothing when adding.
  Future<void> delete() async {
    final existing = original;
    if (existing == null || state.busy) return;
    emit(const RecurringFormState(status: RecurringFormStatus.deleting));

    try {
      await _repository.delete(existing.id);
      emit(const RecurringFormState(status: RecurringFormStatus.deleted));
    } on StorageException {
      emit(
        const RecurringFormState(
          status: RecurringFormStatus.failed,
          failure: StorageFailure(),
        ),
      );
    }
  }
}
