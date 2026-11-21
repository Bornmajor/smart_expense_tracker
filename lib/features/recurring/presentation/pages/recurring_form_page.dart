import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../expenses/domain/validation/expense_rules.dart';
import '../../../expenses/presentation/widgets/category_picker.dart';
import '../../../expenses/presentation/widgets/date_field.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/recurrence_frequency.dart';
import '../../domain/entities/recurring_rule.dart';
import '../../domain/validation/recurring_checks.dart';
import '../cubit/recurring_form_cubit.dart';
import '../cubit/recurring_form_state.dart';
import '../recurring_messages.dart';

/// The form for a recurring expense, or for editing one when [original] is
/// given. The cubit above it decides which; this page only changes its wording.
class RecurringFormPage extends StatefulWidget {
  const RecurringFormPage({super.key, this.original});

  final RecurringRule? original;

  @override
  State<RecurringFormPage> createState() => _RecurringFormPageState();
}

class _RecurringFormPageState extends State<RecurringFormPage> {
  late final TextEditingController _title;
  late final TextEditingController _vendor;
  late final TextEditingController _amount;
  late RecurrenceFrequency _frequency;
  late DateTime _nextDue;
  late String? _categoryId;
  late bool _isActive;

  bool get _isEditing => widget.original != null;

  @override
  void initState() {
    super.initState();
    final original = widget.original;
    _title = TextEditingController(text: original?.title ?? '');
    // A blank vendor is stored as "Unknown"; show it blank again when editing.
    _vendor = TextEditingController(
      text: original == null || original.vendor == ExpenseRules.unknownVendor
          ? ''
          : original.vendor,
    );
    _amount = TextEditingController(
      text: original == null ? '' : Money.toInputText(original.amountMinor),
    );
    _frequency = original?.frequency ?? RecurrenceFrequency.monthly;
    _nextDue = original?.nextDue ?? ExpenseRules.dayOnly(DateTime.now());
    _categoryId = original?.categoryId;
    _isActive = original?.isActive ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _vendor.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<RecurringFormCubit>().submit(
      title: _title.text,
      vendor: _vendor.text,
      amountText: _amount.text,
      categoryId: _categoryId,
      frequency: _frequency,
      nextDue: _nextDue,
      isActive: _isActive,
    );
  }

  Future<void> _confirmDelete() async {
    final cubit = context.read<RecurringFormCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this recurring expense?'),
        content: const Text(
          'It will stop adding expenses. The ones it already added stay.',
        ),
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

  void _onStateChanged(BuildContext context, RecurringFormState state) {
    switch (state.status) {
      case RecurringFormStatus.saved:
        final added = state.addedCount;
        context.showSuccess(
          added == 0
              ? 'Saved'
              : added == 1
              ? 'Saved, and 1 expense added'
              : 'Saved, and $added expenses added',
        );
        context.pop();
      case RecurringFormStatus.deleted:
        context.showSuccess('Recurring expense deleted');
        context.pop();
      case RecurringFormStatus.failed:
        context.showError(
          _isEditing
              ? 'Couldn\'t update it. Try again.'
              : 'Couldn\'t save it. Try again.',
        );
      case RecurringFormStatus.editing ||
          RecurringFormStatus.saving ||
          RecurringFormStatus.deleting:
        break;
    }
  }

  String? _error(RecurringFormState state, String field) {
    final code = state.fieldErrors[field];
    return code == null ? null : recurringErrorMessage(code);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RecurringFormCubit, RecurringFormState>(
      listener: _onStateChanged,
      builder: (context, state) {
        final saving = state.status == RecurringFormStatus.saving;
        final currency = context.select<SettingsCubit, Currency>(
          (cubit) => cubit.state.currency,
        );
        final today = ExpenseRules.dayOnly(DateTime.now());
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _isEditing ? 'Edit recurring expense' : 'Add recurring expense',
            ),
            actions: [
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete recurring expense',
                  onPressed: state.busy ? null : _confirmDelete,
                ),
            ],
          ),
          // The app bar handles the top; this keeps the form and the Save
          // button clear of the gesture bar and any side notch.
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
                        decoration: InputDecoration(
                          labelText: 'Name',
                          hintText: 'For example, Netflix or Rent',
                          errorText: _error(state, RecurringField.name),
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      TextField(
                        controller: _title,
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(
                            ExpenseRules.maxTitleLength,
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                          hintText: 'For example, Family plan',
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
                          labelText: currency.code.isEmpty
                              ? 'Amount each time'
                              : 'Amount each time (${currency.code})',
                          errorText: _error(state, RecurringField.amount),
                        ),
                      ),
                      const Gap(AppSpacing.lg),
                      Text('Repeats', style: context.text.bodyMedium),
                      const Gap(AppSpacing.sm),
                      SegmentedButton<RecurrenceFrequency>(
                        segments: [
                          for (final f in RecurrenceFrequency.values)
                            ButtonSegment(value: f, label: Text(f.label)),
                        ],
                        selected: {_frequency},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) =>
                            setState(() => _frequency = selection.first),
                      ),
                      const Gap(AppSpacing.lg),
                      DateField(
                        date: _nextDue,
                        label: _isEditing ? 'Next date' : 'First date',
                        errorText: _error(state, RecurringField.date),
                        firstDate: DateTime(
                          today.year,
                          today.month,
                          today.day - RecurringChecks.maxDaysBack,
                        ),
                        lastDate: DateTime(
                          today.year,
                          today.month,
                          today.day + RecurringChecks.maxDaysAhead,
                        ),
                        onChanged: (value) => setState(() => _nextDue = value),
                      ),
                      const Gap(AppSpacing.xs),
                      Text(
                        'An expense is added on this date, and again each '
                        'time it comes around. A date in the past adds the '
                        'ones you missed.',
                        style: context.text.bodySmall,
                      ),
                      const Gap(AppSpacing.xl),
                      CategoryPicker(
                        selectedId: _categoryId,
                        errorText: _error(state, RecurringField.category),
                        onSelected: (id) => setState(() => _categoryId = id),
                      ),
                      if (_isEditing) ...[
                        const Gap(AppSpacing.lg),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Active'),
                          subtitle: const Text(
                            'Turn off to pause it. It adds nothing while '
                            'paused.',
                          ),
                          value: _isActive,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                        ),
                      ],
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
                        : Text(_isEditing ? 'Save changes' : 'Save'),
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
