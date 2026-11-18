import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../domain/entities/expense.dart';
import '../../domain/validation/expense_rules.dart';
import '../../domain/validation/expense_validation.dart';
import '../cubit/expense_form_cubit.dart';
import '../cubit/expense_form_state.dart';
import '../validation_messages.dart';
import '../widgets/category_picker.dart';
import '../widgets/date_field.dart';

/// The form for adding an expense, or editing one when [original] is given.
/// The cubit above it decides which; this page only changes its wording.
class ExpenseFormPage extends StatefulWidget {
  const ExpenseFormPage({super.key, this.original});

  final Expense? original;

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  late final TextEditingController _vendor;
  late final TextEditingController _amount;
  late DateTime _date;
  late String? _categoryId;

  bool get _isEditing => widget.original != null;

  @override
  void initState() {
    super.initState();
    final original = widget.original;
    // A blank vendor is stored as "Unknown"; show it blank again when editing.
    _vendor = TextEditingController(
      text: original == null || original.vendor == ExpenseRules.unknownVendor
          ? ''
          : original.vendor,
    );
    _amount = TextEditingController(
      text: original == null ? '' : Money.toInputText(original.amountMinor),
    );
    _date = original?.date ?? DateTime.now();
    _categoryId = original?.categoryId;
  }

  @override
  void dispose() {
    _vendor.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<ExpenseFormCubit>().submit(
      vendor: _vendor.text,
      amountText: _amount.text,
      date: _date,
      categoryId: _categoryId,
    );
  }

  Future<void> _confirmDelete() async {
    final cubit = context.read<ExpenseFormCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this expense?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) cubit.delete();
  }

  void _onStateChanged(BuildContext context, ExpenseFormState state) {
    switch (state.status) {
      case ExpenseFormStatus.saved:
        context.showSuccess(_isEditing ? 'Expense updated' : 'Expense saved');
        context.pop();
      case ExpenseFormStatus.deleted:
        context.showSuccess('Expense deleted');
        context.pop();
      case ExpenseFormStatus.failed:
        context.showError(
          _isEditing
              ? 'Couldn\'t update the expense. Try again.'
              : 'Couldn\'t save the expense. Try again.',
        );
      case ExpenseFormStatus.editing ||
          ExpenseFormStatus.saving ||
          ExpenseFormStatus.deleting:
        break;
    }
  }

  String? _error(ExpenseFormState state, String field) {
    final code = state.fieldErrors[field];
    return code == null ? null : expenseErrorMessage(code);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExpenseFormCubit, ExpenseFormState>(
      listener: _onStateChanged,
      builder: (context, state) {
        final saving = state.status == ExpenseFormStatus.saving;
        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit expense' : 'Add expense'),
            actions: [
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete expense',
                  onPressed: state.busy ? null : _confirmDelete,
                ),
            ],
          ),
          // The app bar handles the top; this keeps the form and the Save
          // button clear of the gesture bar and any side notch. The Scaffold
          // shrinks the body when the keyboard opens, so the pinned button
          // moves up and stays visible above it.
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: AppSpacing.screen.copyWith(bottom: AppSpacing.md),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      TextField(
                        controller: _vendor,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Vendor (optional)',
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      TextField(
                        controller: _amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          errorText: _error(state, ExpenseField.amount),
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      DateField(
                        date: _date,
                        errorText: _error(state, ExpenseField.date),
                        onChanged: (value) => setState(() => _date = value),
                      ),
                      const Gap(AppSpacing.xl),
                      CategoryPicker(
                        selectedId: _categoryId,
                        errorText: _error(state, ExpenseField.category),
                        onSelected: (id) => setState(() => _categoryId = id),
                      ),
                    ],
                  ),
                ),
                // Pinned to the bottom, outside the scrolling form.
                Padding(
                  padding: AppSpacing.screen.copyWith(top: AppSpacing.sm),
                  child: FilledButton(
                    onPressed: state.busy ? null : _submit,
                    child: saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEditing ? 'Save changes' : 'Save expense'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
