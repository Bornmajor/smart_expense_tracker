import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/cubit/categories_state.dart';

/// Chips for choosing a category. Reads the list from CategoriesCubit.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    super.key,
    required this.selectedId,
    required this.onSelected,
    this.errorText,
  });

  final String? selectedId;
  final ValueChanged<String> onSelected;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: context.text.bodyMedium),
        const Gap(AppSpacing.sm),
        BlocBuilder<CategoriesCubit, CategoriesState>(
          builder: (context, state) => switch (state) {
            CategoriesLoading() => const LinearProgressIndicator(),
            CategoriesError() => const Text('Couldn\'t load categories'),
            CategoriesLoaded(:final categories) => Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final category in categories)
                  ChoiceChip(
                    label: Text(category.name),
                    selected: category.id == selectedId,
                    onSelected: (_) => onSelected(category.id),
                  ),
              ],
            ),
          },
        ),
        if (errorText != null) ...[
          const Gap(AppSpacing.sm),
          Text(
            errorText!,
            style: context.text.bodySmall?.copyWith(
              color: context.scheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
