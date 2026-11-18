import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../domain/entities/category.dart';
import '../../domain/validation/category_rules.dart';
import '../category_validation_messages.dart';
import '../cubit/categories_cubit.dart';
import '../cubit/categories_state.dart';
import '../cubit/category_actions_cubit.dart';
import '../widgets/category_name_sheet.dart';

/// Add, rename and delete categories.
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  Future<void> _add(BuildContext context) async {
    final actions = context.read<CategoryActionsCubit>();
    final saved = await showCategoryNameSheet(
      context,
      title: 'New category',
      submitLabel: 'Add category',
      onSubmit: (name) async => switch (await actions.create(name)) {
        Failure(:final failure) => categorySaveError(failure),
        _ => null,
      },
    );
    if (saved == true && context.mounted) context.showSuccess('Category added');
  }

  Future<void> _rename(BuildContext context, Category category) async {
    final actions = context.read<CategoryActionsCubit>();
    final saved = await showCategoryNameSheet(
      context,
      title: 'Rename category',
      submitLabel: 'Save name',
      initialName: category.name,
      onSubmit: (name) async => switch (await actions.rename(category, name)) {
        Failure(:final failure) => categorySaveError(failure),
        _ => null,
      },
    );
    if (saved == true && context.mounted) {
      context.showSuccess('Category renamed');
    }
  }

  Future<void> _delete(
    BuildContext context,
    Category category,
    String fallbackName,
  ) async {
    final actions = context.read<CategoryActionsCubit>();
    final count = await actions.expenseCount(category.id);
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${category.name}?'),
        content: Text(
          count == 0
              ? 'No expenses use this category.'
              : '${_expenses(count)} in this category will move to '
                    '$fallbackName.',
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
    if (confirmed != true) return;

    final result = await actions.delete(category);
    if (!context.mounted) return;

    switch (result) {
      case Success(value: final moved):
        context.showSuccess(
          moved == 0
              ? 'Deleted ${category.name}'
              : 'Deleted ${category.name}. ${_expenses(moved)} moved to '
                    '$fallbackName.',
        );
      case Failure(failure: final ValidationFailure validation):
        context.showError(
          categoryErrorMessage(
            validation.fieldErrors[CategoryField.name] ?? '',
          ),
        );
      case Failure():
        context.showError('Couldn\'t delete the category. Try again.');
      case null:
        break;
    }
  }

  String _expenses(int count) => count == 1 ? '1 expense' : '$count expenses';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
      // The app bar handles the top; this keeps the list clear of the
      // gesture bar and any side notch.
      body: SafeArea(
        top: false,
        child: BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, state) => switch (state) {
            CategoriesLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            CategoriesError() => const Center(
              child: Text('Couldn\'t load categories'),
            ),
            CategoriesLoaded(:final categories) => _CategoryList(
              categories: categories,
              onRename: (category) => _rename(context, category),
              onDelete: (category, fallbackName) =>
                  _delete(context, category, fallbackName),
            ),
          },
        ),
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.categories,
    required this.onRename,
    required this.onDelete,
  });

  final List<Category> categories;
  final ValueChanged<Category> onRename;
  final void Function(Category category, String fallbackName) onDelete;

  @override
  Widget build(BuildContext context) {
    final fallbackName = categories
        .firstWhere((c) => c.isFallback, orElse: () => categories.first)
        .name;

    return ListView.separated(
      padding: AppSpacing.screen.copyWith(top: AppSpacing.sm, bottom: 96),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            title: Text(category.name),
            subtitle: category.isFallback
                ? Text(
                    'Takes expenses from deleted categories',
                    style: context.text.bodySmall,
                  )
                : null,
            onTap: () => onRename(category),
            // The fallback can be renamed, but never deleted.
            trailing: category.isFallback
                ? const Icon(Icons.edit_outlined)
                : IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete ${category.name}',
                    onPressed: () => onDelete(category, fallbackName),
                  ),
          ),
        );
      },
    );
  }
}
