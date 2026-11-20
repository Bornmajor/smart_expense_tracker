import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/utils/currency.dart';

/// What the user did in the budget sheet.
enum BudgetSheetResult { saved, removed }

/// Asks for a monthly limit in a bottom sheet.
///
/// [onSave] saves the typed amount and returns an error message to show under
/// the field, or null when it worked (the sheet then closes). With [onRemove]
/// the sheet also offers to remove the budget.
Future<BudgetSheetResult?> showBudgetSheet(
  BuildContext context, {
  required String title,
  required Currency currency,
  required Future<String?> Function(String amountText) onSave,
  Future<bool> Function()? onRemove,
  String initialText = '',
}) => showModalBottomSheet<BudgetSheetResult>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _BudgetLimitSheet(
    title: title,
    currency: currency,
    initialText: initialText,
    onSave: onSave,
    onRemove: onRemove,
  ),
);

class _BudgetLimitSheet extends StatefulWidget {
  const _BudgetLimitSheet({
    required this.title,
    required this.currency,
    required this.initialText,
    required this.onSave,
    required this.onRemove,
  });

  final String title;
  final Currency currency;
  final String initialText;
  final Future<String?> Function(String amountText) onSave;
  final Future<bool> Function()? onRemove;

  @override
  State<_BudgetLimitSheet> createState() => _BudgetLimitSheetState();
}

class _BudgetLimitSheetState extends State<_BudgetLimitSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.initialText,
  );
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final error = await widget.onSave(_amount.text);
    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(BudgetSheetResult.saved);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  Future<void> _remove() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final removed = await widget.onRemove!();
    if (!mounted) return;

    if (removed) {
      Navigator.of(context).pop(BudgetSheetResult.removed);
    } else {
      setState(() {
        _busy = false;
        _error = 'Couldn\'t remove the budget. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.currency.code;
    // The sheet lifts above the keyboard; SafeArea clears the gesture bar.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screen.copyWith(bottom: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: context.text.titleLarge),
              const Gap(AppSpacing.xs),
              Text(
                'How much you plan to spend each month.',
                style: context.text.bodySmall,
              ),
              const Gap(AppSpacing.lg),
              TextField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  labelText: code.isEmpty
                      ? 'Monthly limit'
                      : 'Monthly limit ($code)',
                  errorText: _error,
                ),
              ),
              const Gap(AppSpacing.lg),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save budget'),
              ),
              if (widget.onRemove != null) ...[
                const Gap(AppSpacing.sm),
                TextButton(
                  onPressed: _busy ? null : _remove,
                  child: const Text('Remove budget'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
