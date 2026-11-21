import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';
import '../../../../core/utils/money.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/expense_filter.dart';

/// Bottom sheet for narrowing the list by category, dates and amount. Returns
/// the new filter, or null when the sheet is closed without applying. The
/// search words are kept as they are.
Future<ExpenseFilter?> showExpenseFilterSheet(
  BuildContext context, {
  required ExpenseFilter current,
  required List<Category> categories,
  required Currency currency,
}) {
  return showModalBottomSheet<ExpenseFilter>(
    context: context,
    isScrollControlled: true,
    // The list sits under the app's tab bar and button; the root navigator
    // puts the sheet above them.
    useRootNavigator: true,
    builder: (context) => _FilterSheet(
      current: current,
      categories: categories,
      currency: currency,
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.current,
    required this.categories,
    required this.currency,
  });

  final ExpenseFilter current;
  final List<Category> categories;
  final Currency currency;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _categoryId = widget.current.categoryId;
  late DateTime? _from = widget.current.from;
  late DateTime? _to = widget.current.to;
  late final TextEditingController _min = TextEditingController(
    text: _inputText(widget.current.minMinor),
  );
  late final TextEditingController _max = TextEditingController(
    text: _inputText(widget.current.maxMinor),
  );
  String? _amountError;

  static String _inputText(int? minor) =>
      minor == null ? '' : Money.toInputText(minor);

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  Future<void> _chooseDates() async {
    final today = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year, today.month, today.day),
      initialDateRange: _from != null && _to != null
          ? DateTimeRange(start: _from!, end: _to!)
          : null,
      helpText: 'Show expenses between',
    );
    if (range == null || !mounted) return;
    setState(() {
      _from = range.start;
      _to = range.end;
    });
  }

  void _apply() {
    final min = Money.tryParse(_min.text);
    final max = Money.tryParse(_max.text);
    final badMin = _min.text.trim().isNotEmpty && min == null;
    final badMax = _max.text.trim().isNotEmpty && max == null;
    if (badMin || badMax) {
      setState(() => _amountError = 'Enter amounts like 120 or 12.50');
      return;
    }
    if (min != null && max != null && min > max) {
      setState(() => _amountError = 'The lowest can\'t be above the highest');
      return;
    }

    final base = widget.current.copyWith(
      clearCategory: true,
      clearDates: true,
      clearAmount: true,
    );
    Navigator.pop(
      context,
      base.copyWith(
        categoryId: _categoryId,
        from: _from,
        to: _to,
        minMinor: min,
        maxMinor: max,
      ),
    );
  }

  void _clear() {
    setState(() {
      _categoryId = null;
      _from = null;
      _to = null;
      _min.clear();
      _max.clear();
      _amountError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final format = DateFormat.yMMMd();
    final dates = _from == null || _to == null
        ? 'Any date'
        : '${format.format(_from!)} to ${format.format(_to!)}';
    final label = widget.currency.code.isEmpty
        ? ''
        : ' (${widget.currency.code})';

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        // One scrolling list, so a small phone with large text or the open
        // keyboard never cuts anything off.
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            Text('Filter expenses', style: context.text.titleLarge),
            const Gap(AppSpacing.lg),
            Text('Category', style: context.text.titleSmall),
            const Gap(AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: const Text('Any'),
                  selected: _categoryId == null,
                  onSelected: (_) => setState(() => _categoryId = null),
                ),
                for (final category in widget.categories)
                  ChoiceChip(
                    label: Text(category.name),
                    selected: _categoryId == category.id,
                    onSelected: (_) =>
                        setState(() => _categoryId = category.id),
                  ),
              ],
            ),
            const Gap(AppSpacing.lg),
            Text('Dates', style: context.text.titleSmall),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.date_range_outlined),
              title: Text(dates),
              trailing: _from == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(
                      tooltip: 'Any date',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        _from = null;
                        _to = null;
                      }),
                    ),
              onTap: _chooseDates,
            ),
            const Gap(AppSpacing.sm),
            Text('Amount$label', style: context.text.titleSmall),
            const Gap(AppSpacing.sm),
            Row(
              children: [
                Expanded(child: _amountField(_min, 'Lowest')),
                const Gap(AppSpacing.md),
                Expanded(child: _amountField(_max, 'Highest')),
              ],
            ),
            if (_amountError != null) ...[
              const Gap(AppSpacing.xs),
              Text(
                _amountError!,
                style: context.text.bodySmall?.copyWith(
                  color: context.scheme.error,
                ),
              ),
            ],
            const Gap(AppSpacing.xl),
            Row(
              children: [
                TextButton(onPressed: _clear, child: const Text('Clear')),
                const Gap(AppSpacing.md),
                // The theme makes filled buttons full width, so it needs room to
                // take rather than a place in the middle of a row.
                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      onChanged: (_) {
        if (_amountError != null) setState(() => _amountError = null);
      },
      decoration: InputDecoration(labelText: label),
    );
  }
}
