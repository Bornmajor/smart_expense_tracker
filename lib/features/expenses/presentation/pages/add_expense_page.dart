import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../domain/validation/expense_validation.dart';
import '../cubit/add_expense_cubit.dart';
import '../cubit/add_expense_state.dart';
import '../validation_messages.dart';
import '../widgets/category_picker.dart';
import '../widgets/date_field.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _vendor = TextEditingController();
  final _amount = TextEditingController();
  DateTime _date = DateTime.now();
  String? _categoryId;

  @override
  void dispose() {
    _vendor.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AddExpenseCubit>().submit(
      vendor: _vendor.text,
      amountText: _amount.text,
      date: _date,
      categoryId: _categoryId,
    );
  }

  void _onStateChanged(BuildContext context, AddExpenseState state) {
    switch (state.status) {
      case AddExpenseStatus.saved:
        context.showSuccess('Expense saved');
        context.pop();
      case AddExpenseStatus.failed:
        context.showError('Couldn\'t save the expense. Try again.');
      case AddExpenseStatus.editing || AddExpenseStatus.saving:
        break;
    }
  }

  String? _error(AddExpenseState state, String field) {
    final code = state.fieldErrors[field];
    return code == null ? null : expenseErrorMessage(code);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddExpenseCubit, AddExpenseState>(
      listener: _onStateChanged,
      builder: (context, state) {
        final saving = state.status == AddExpenseStatus.saving;
        return Scaffold(
          appBar: AppBar(title: const Text('Add expense')),
          // The app bar handles the top; this keeps the form and the Save
          // button clear of the gesture bar and any side notch.
          body: SafeArea(
            top: false,
            child: ListView(
              padding: AppSpacing.screen,
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
                const Gap(AppSpacing.xxl),
                FilledButton(
                  onPressed: saving ? null : _submit,
                  child: saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save expense'),
                ),
                const Gap(AppSpacing.xl),
              ],
            ),
          ),
        );
      },
    );
  }
}
