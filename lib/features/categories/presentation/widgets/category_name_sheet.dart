import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../domain/validation/category_rules.dart';

/// Asks for a category name in a bottom sheet. Resolves to true once the name
/// was saved, and to null if the user closed the sheet.
///
/// [onSubmit] saves the name and returns an error message to show under the
/// field, or null when it worked (the sheet then closes).
Future<bool?> showCategoryNameSheet(
  BuildContext context, {
  required String title,
  required String submitLabel,
  required Future<String?> Function(String name) onSubmit,
  String initialName = '',
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => CategoryNameSheet(
    title: title,
    submitLabel: submitLabel,
    initialName: initialName,
    onSubmit: onSubmit,
  ),
);

class CategoryNameSheet extends StatefulWidget {
  const CategoryNameSheet({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.onSubmit,
    this.initialName = '',
  });

  final String title;
  final String submitLabel;
  final String initialName;
  final Future<String?> Function(String name) onSubmit;

  @override
  State<CategoryNameSheet> createState() => _CategoryNameSheetState();
}

class _CategoryNameSheetState extends State<CategoryNameSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await widget.onSubmit(_name.text);
    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // The sheet lifts above the keyboard; SafeArea clears the gesture bar.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: AppSpacing.screen.copyWith(bottom: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.title, style: context.text.titleLarge),
              const Gap(AppSpacing.lg),
              TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(CategoryRules.maxNameLength),
                ],
                decoration: InputDecoration(
                  labelText: 'Name',
                  errorText: _error,
                ),
              ),
              const Gap(AppSpacing.lg),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.submitLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
