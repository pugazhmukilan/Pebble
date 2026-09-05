import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/expense/expense_cubit.dart';
import '../constants/category_colors.dart';
import '../models/category.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'category_editor_sheet.dart';
import 'category_icon.dart';

/// Grid of category icons + an Add New button.
/// Tap → select. Long-press → edit / delete options.
///
/// Category color is NEVER used here (§5.3): every tile renders on the
/// same neutral chip, selection is communicated with text weights only.
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  final List<ExpenseCategory> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onCategorySelected;

  Future<void> _openEditor(
    BuildContext context,
    ExpenseCategory? category,
  ) async {
    final colors = AppColors.of(context);
    final result = await showModalBottomSheet<ExpenseCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusCard),
        ),
      ),
      builder: (_) => CategoryEditorSheet(
        category: category,
        existingCategories: categories,
      ),
    );
    if (result == null) return;
    if (!context.mounted) return;

    final cubit = context.read<ExpenseCubit>();
    if (category == null) {
      await cubit.repository.addCategory(result);
      await cubit.loadExpenses();
      onCategorySelected(result.id);
    } else {
      await cubit.updateCategory(result);
    }
  }

  void _showCategoryOptions(BuildContext context, ExpenseCategory category) {
    // The system-reserved "Other" is not user-editable or deletable (§1.3).
    if (category.id == kOtherCategoryId) return;

    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusCard),
        ),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.edit_rounded,
                color: colors.textPrimary,
              ),
              title: Text('Edit category', style: styles.listRowTitle),
              onTap: () {
                Navigator.pop(sheetCtx);
                _openEditor(context, category);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_rounded,
                color: colors.signalExpense,
              ),
              title: Text(
                'Delete category',
                style: styles.listRowTitle.copyWith(
                  color: colors.signalExpense,
                ),
              ),
              onTap: () async {
                Navigator.pop(sheetCtx);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete category?'),
                    content: Text(
                      'All expenses in "${category.label}" will be moved to Other.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.signalExpense,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  context.read<ExpenseCubit>().deleteCategory(category.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    return GridView.count(
      crossAxisCount: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.xs,
      crossAxisSpacing: AppSpacing.xs,
      childAspectRatio: 0.95,
      children: [
        ...categories.map((category) {
          final isSelected = category.id == selectedCategoryId;
          return GestureDetector(
            onTap: () => onCategorySelected(category.id),
            onLongPress: () => _showCategoryOptions(context, category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? colors.surfaceRaised : colors.surfaceRaised,
                borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                border: Border.all(
                  color: isSelected
                      ? colors.textPrimary
                      : colors.borderHairline,
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CategoryIcon(
                    category: category,
                    size: 22,
                    color:
                        isSelected ? colors.textPrimary : colors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Text(
                      category.label,
                      style: isSelected
                          ? styles.chipLabel.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            )
                          : styles.chipLabel.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        // Add New button
        GestureDetector(
          onTap: () => _openEditor(context, null),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
              border: Border.all(color: colors.borderHairline, width: 0.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 22, color: colors.textSecondary),
                const SizedBox(height: AppSpacing.xs),
                Text('Add New', style: styles.chipLabel.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}