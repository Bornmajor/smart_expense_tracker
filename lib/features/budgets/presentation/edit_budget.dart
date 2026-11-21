import 'package:flutter/material.dart';

import '../../../core/errors/result.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../domain/entities/budget.dart';
import 'budget_messages.dart';
import 'cubit/budgets_cubit.dart';
import 'widgets/budget_limit_sheet.dart';

/// Opens the sheet to set, change or remove one monthly budget, and says what
/// happened. [scopeId] is a category id, or [Budget.overallId]. Used from the
/// Budgets screen and from a category's page, so both behave the same.
///
/// [hint] is a line under the field, such as what was spent this month.
Future<void> editBudget(
  BuildContext context, {
  required BudgetsCubit cubit,
  required String scopeId,
  required String title,
  required Budget? existing,
  required Currency currency,
  String? hint,
}) async {
  final result = await showBudgetSheet(
    context,
    title: title,
    currency: currency,
    hint: hint,
    initialText: existing == null ? '' : Money.toInputText(existing.limitMinor),
    onSave: (text) async => switch (await cubit.save(scopeId, text)) {
      Failure(:final failure) => budgetSaveError(failure),
      _ => null,
    },
    onRemove: existing == null
        ? null
        : () async => await cubit.remove(scopeId) is Success<void>,
  );
  if (!context.mounted) return;
  switch (result) {
    case BudgetSheetResult.saved:
      context.showSuccess('Budget saved');
    case BudgetSheetResult.removed:
      context.showInfo('Budget removed');
    case null:
      break;
  }
}
