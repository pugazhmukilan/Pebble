import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/expense/expense_cubit.dart';
import '../models/category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'category_editor_sheet.dart';
import 'category_icon.dart';

/// Grid of category icons + an Add New button.
/// Tap → select. Long-press → edit / delete options.
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
    final result = await showModalBottomSheet<ExpenseCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.edit_rounded,
                color: AppColors.textPrimary,
              ),
              title: const Text(
                'Edit category',
                style: AppTextStyles.expenseLabel,
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                _openEditor(context, category);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_rounded,
                color: AppColors.destructive,
              ),
              title: Text(
                'Delete category',
                style: AppTextStyles.expenseLabel.copyWith(
                  color: AppColors.destructive,
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
                          foregroundColor: AppColors.destructive,
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1,
      children: [
        ...categories.map((category) {
          final isSelected = category.id == selectedCategoryId;
          final color = Color(category.colorValue);
          return GestureDetector(
            onTap: () => onCategorySelected(category.id),
            onLongPress: () => _showCategoryOptions(context, category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: isSelected ? 1.5 : 0.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CategoryIcon(
                    category: category,
                    size: 24,
                    color: isSelected ? color : AppColors.textMuted,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      category.label,
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected ? color : AppColors.textMuted,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, size: 24, color: AppColors.textMuted),
                SizedBox(height: 4),
                Text('Add New', style: AppTextStyles.caption),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
