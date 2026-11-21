import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/category_validation_messages.dart';
import '../../../categories/presentation/cubit/category_actions_cubit.dart';
import '../../../categories/presentation/widgets/category_name_sheet.dart';
import '../../../scan/domain/entities/scan_result.dart';
import '../../../scan/presentation/widgets/receipt_viewer.dart';
import '../../../scan/presentation/widgets/scan_review_panel.dart';
import '../../../currency_conversion/domain/entities/exchange_rates.dart';
import '../../../currency_conversion/domain/repositories/exchange_rate_repository.dart';
import '../../../recurring/domain/entities/recurrence_frequency.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/expense.dart';
import '../../domain/usecases/vendor_category_memory.dart';
import '../../domain/validation/expense_rules.dart';
import '../../domain/validation/expense_validation.dart';
import '../cubit/expense_form_cubit.dart';
import '../cubit/expense_form_state.dart';
import '../validation_messages.dart';
import '../widgets/category_picker.dart';
import '../widgets/currency_converter.dart';
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

  /// True when the user wants this expense to repeat. Only offered when adding.
  /// The other currency the amount is written in, or null for the app's own.
  Currency? _from;
  ExchangeRates? _rates;

  bool _repeat = false;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  final _vendorFocus = FocusNode();

  /// True while the category was filled in from the user's earlier expenses
  /// at this vendor, and not chosen by them. Only then may a new vendor
  /// replace it; a category the user picked is never changed behind their back.
  bool _categoryIsAuto = false;

  /// Says why the category was filled in. Gone once the user picks one.
  String? _categoryHint;

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
    // A suggestion from the scan can be replaced if the user fixes the vendor.
    _categoryIsAuto = scan?.suggestedCategoryId != null;
    if (!_isEditing) _vendorFocus.addListener(_onVendorFocusChanged);
  }

  @override
  void dispose() {
    final scan = widget.scan;
    if (scan != null) widget.discardPhoto?.call(scan.photoPath);
    _vendorFocus.dispose();
    _title.dispose();
    _vendor.dispose();
    _amount.dispose();
    super.dispose();
  }

  /// When the user leaves the vendor field, picks the category they gave this
  /// vendor before. It never replaces a category the user chose themselves.
  void _onVendorFocusChanged() {
    if (!_vendorFocus.hasFocus) _suggestCategory();
  }

  Future<void> _suggestCategory() async {
    if (_categoryId != null && !_categoryIsAuto) return;

    final vendor = _vendor.text.trim();
    final id = await context.read<VendorCategoryMemory>().categoryFor(vendor);

    // The user may have picked a category, or left, while this was running.
    if (!mounted || id == null || id == _categoryId) return;
    if (_categoryId != null && !_categoryIsAuto) return;

    setState(() {
      _categoryId = id;
      _categoryIsAuto = true;
      _categoryHint = 'Chosen from your earlier expenses at $vendor.';
    });
  }

  void _selectCategory(String id) {
    setState(() {
      _categoryId = id;
      _categoryIsAuto = false;
      _categoryHint = null;
    });
  }

  Future<void> _chooseCurrency(Currency appCurrency) async {
    final repository = context.read<ExchangeRateRepository>();
    final picked = await showOtherCurrencySheet(
      context,
      appCurrency: appCurrency,
    );
    if (picked == null || !mounted) return;
    setState(() => _from = picked);
    // Shows the saved rates at once, then newer ones if they arrive.
    final saved = await repository.saved();
    if (mounted) setState(() => _rates = saved);
    final fresh = await repository.refresh();
    if (mounted) setState(() => _rates = fresh);
  }

  void _submit() {
    context.read<ExpenseFormCubit>().submit(
      title: _title.text,
      vendor: _vendor.text,
      amountText: _amount.text,
      date: _date,
      categoryId: _categoryId,
      repeat: _repeat ? _frequency : null,
      fromCurrency: _from?.code,
      toCurrency: context.read<SettingsCubit>().state.currency.code,
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
    if (category != null && mounted) _selectCategory(category.id);
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

  /// For an expense that was converted: what was actually paid.
  String? _originalNote() {
    final original = widget.original;
    final minor = original?.originalAmountMinor;
    final code = original?.originalCurrency;
    if (minor == null || code == null) return null;
    final text =
        Currency.byCode(code)?.formatWithCode(minor) ??
        '$code ${Money.format(minor)}';
    return 'Originally $text';
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
        final currency = context.select<SettingsCubit, Currency>(
          (cubit) => cubit.state.currency,
        );
        return Scaffold(
          appBar: AppBar(
            title: Text(_isEditing ? 'Edit expense' : 'Add expense'),
            actions: [
              // After a scan: the receipt is one tap away, even when the form has
              // been scrolled down to the category or the Save button.
              if (widget.scan != null)
                IconButton(
                  icon: const Icon(Icons.receipt_long_outlined),
                  tooltip: 'View receipt',
                  onPressed: () =>
                      showReceiptViewer(context, widget.scan!.photoPath),
                ),
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
                        focusNode: _vendorFocus,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Vendor (optional)',
                        ),
                      ),
                      const Gap(AppSpacing.md),
                      TextField(
                        controller: _amount,
                        onChanged: _from == null
                            ? null
                            : (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: InputDecoration(
                          labelText: _from != null
                              ? 'Amount (${_from!.code})'
                              : currency.code.isEmpty
                              ? 'Amount'
                              : 'Amount (${currency.code})',
                          errorText: _error(state, ExpenseField.amount),
                          helperText: _originalNote(),
                        ),
                      ),
                      // Needs a currency of its own to convert into, and is for new
                      // expenses only: an edit keeps the figure it already has.
                      if (!_isEditing && currency.code.isNotEmpty)
                        CurrencyConverter(
                          appCurrency: currency,
                          from: _from,
                          rates: _rates,
                          amountText: _amount.text,
                          onChoose: () => _chooseCurrency(currency),
                          onClear: () => setState(() => _from = null),
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
                        onSelected: _selectCategory,
                        onAdd: _addCategory,
                      ),
                      if (_categoryHint != null) ...[
                        const Gap(AppSpacing.sm),
                        Text(_categoryHint!, style: context.text.bodySmall),
                      ],
                      if (!_isEditing) ...[
                        const Gap(AppSpacing.md),
                        _RepeatOption(
                          repeat: _repeat,
                          frequency: _frequency,
                          enabled: !saving,
                          onRepeatChanged: (value) =>
                              setState(() => _repeat = value),
                          onFrequencyChanged: (value) =>
                              setState(() => _frequency = value),
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

/// "Repeat this expense", for a bill that comes back, with how often.
class _RepeatOption extends StatelessWidget {
  const _RepeatOption({
    required this.repeat,
    required this.frequency,
    required this.enabled,
    required this.onRepeatChanged,
    required this.onFrequencyChanged,
  });

  final bool repeat;
  final RecurrenceFrequency frequency;
  final bool enabled;
  final ValueChanged<bool> onRepeatChanged;
  final ValueChanged<RecurrenceFrequency> onFrequencyChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: repeat,
          onChanged: enabled
              ? (value) => onRepeatChanged(value ?? false)
              : null,
          title: const Text('Repeat this expense'),
          subtitle: const Text('Add it again automatically, like a bill'),
        ),
        if (repeat)
          SegmentedButton<RecurrenceFrequency>(
            // The tick would take room from the word, so the filled segment
            // alone shows the choice.
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            ),
            segments: [
              for (final option in RecurrenceFrequency.values)
                ButtonSegment(
                  value: option,
                  // One line that shrinks to fit instead of wrapping, so a larger
                  // text size never pushes a word onto a second line.
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(option.label, maxLines: 1, softWrap: false),
                  ),
                ),
            ],
            selected: {frequency},
            onSelectionChanged: enabled
                ? (value) => onFrequencyChanged(value.first)
                : null,
          ),
      ],
    );
  }
}
