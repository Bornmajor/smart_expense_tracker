import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/category_validation_messages.dart';
import '../../../categories/presentation/cubit/category_actions_cubit.dart';
import '../../../categories/presentation/widgets/category_name_sheet.dart';
import '../../../scan/domain/entities/scan_result.dart';
import '../../../scan/presentation/widgets/scan_review_panel.dart';
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
  const ExpenseFormPage({
    super.key,
    this.original,
    this.scan,
    this.discardPhoto,
  });

  final Expense? original;

  /// A scanned receipt that fills in the fields. Only used when adding.
  final ScanResult? scan;

  /// Deletes the receipt photo. Called when the form closes, whether the
  /// expense was saved or not, because the photo is only for comparing.
  final void Function(String photoPath)? discardPhoto;

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  late final TextEditingController _title;
  late final TextEditingController _vendor;
  late final TextEditingController _amount;
  late DateTime _date;
  late String? _categoryId;

  bool get _isEditing => widget.original != null;

  @override
  void initState() {
    super.initState();
    final original = widget.original;
    final scan = widget.scan;
    final draft = scan?.draft;
    _title = TextEditingController(text: original?.title ?? '');
    // A blank vendor is stored as "Unknown"; show it blank again when editing.
    _vendor = TextEditingController(
      text: original != null
          ? (original.vendor == ExpenseRules.unknownVendor
                ? ''
                : original.vendor)
          : draft?.vendor ?? '',
    );
    final scannedTotal = draft?.totalMinor;
    _amount = TextEditingController(
      text: original != null
          ? Money.toInputText(original.amountMinor)
          : scannedTotal == null
          ? ''
          : Money.toInputText(scannedTotal),
    );
    _date = original?.date ?? draft?.date ?? DateTime.now();
    _categoryId = original?.categoryId ?? scan?.suggestedCategoryId;
  }

  @override
  void dispose() {
    final scan = widget.scan;
    if (scan != null) widget.discardPhoto?.call(scan.photoPath);
    _title.dispose();
    _vendor.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<ExpenseFormCubit>().submit(
      title: _title.text,
      vendor: _vendor.text,
      amountText: _amount.text,
      date: _date,
      categoryId: _categoryId,
    );
  }

  /// Adds a category without leaving the form. The sheet is a modal on top of
  /// this page, so everything already typed stays as it is. A name the user
  /// already has picks that category; a new name creates it. Either way the
  /// category ends up selected.
  Future<void> _addCategory() async {
    final actions = context.read<CategoryActionsCubit>();
    Category? chosen;

    await showCategoryNameSheet(
      context,
      title: 'New category',
      submitLabel: 'Add category',
      onSubmit: (name) async {
        switch (await actions.findOrCreate(name)) {
          case Success(:final value):
            chosen = value;
            return null;
          case Failure(:final failure):
            return categorySaveError(failure);
          case null:
            return 'Couldn\'t add the category. Try again.';
        }
      },
    );

    final category = chosen;
    if (category != null && mounted) {
      setState(() => _categoryId = category.id);
    }
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
                      // After a scan: the receipt photo and what to check.
                      if (widget.scan != null) ...[
                        ScanReviewPanel(scan: widget.scan!),
                        const Gap(AppSpacing.lg),
                      ],
                      TextField(
                        controller: _title,
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(
                            ExpenseRules.maxTitleLength,
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Title (optional)',
                          hintText: 'For example, Lunch with team',
                          errorText: _error(state, ExpenseField.title),
                        ),
                      ),
                      const Gap(AppSpacing.md),
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
                        onAdd: _addCategory,
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
