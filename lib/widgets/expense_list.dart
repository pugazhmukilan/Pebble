import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category.dart';
import '../models/expense.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/amount_formatter.dart';
import 'category_icon.dart';

/// Expense list grouped by day, most recent first.
/// Tap a row → details with edit. Swipe → delete, both gated by
/// isCurrentMonth (§8).
///
/// Rows sit directly on the surface base separated by 1px hairline dividers
/// (§4) — no per-row card wrapper. Icon chips are neutral (§4).
class ExpenseList extends StatelessWidget {
  const ExpenseList({
    super.key,
    required this.expenses,
    required this.categories,
    required this.isCurrentMonth,
    required this.onDelete,
    required this.onEdit,
    this.obscured = false,
  });

  final List<Expense> expenses;
  final List<ExpenseCategory> categories;
  final bool isCurrentMonth;
  final void Function(Expense) onDelete;
  final void Function(Expense) onEdit;
  final bool obscured;

  Map<DateTime, List<Expense>> _groupByDay() {
    final grouped = <DateTime, List<Expense>>{};
    for (final expense in expenses) {
      final day = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      grouped.putIfAbsent(day, () => []).add(expense);
    }
    return grouped;
  }

  ExpenseCategory _categoryFor(Expense expense) {
    return categories.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () => categories.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    if (expenses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: colors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('No expenses this month', style: styles.cardLabel),
            ],
          ),
        ),
      );
    }

    final groups = _groupByDay();
    final sortedDays = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedDays.map((day) {
        final dayExpenses = groups[day]!;
        String label;
        if (day == todayDate) {
          label = 'Today';
        } else if (day == todayDate.subtract(const Duration(days: 1))) {
          label = 'Yesterday';
        } else {
          label = DateFormat('EEEE, MMM d').format(day);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Text(
                label.toUpperCase(),
                style: styles.sectionLabel,
              ),
            ),
            ...dayExpenses.map(
              (expense) => _ExpenseRow(
                expense: expense,
                category: _categoryFor(expense),
                isEditable: isCurrentMonth,
                obscured: obscured,
                onTap: () => _showDetails(context, expense),
                onDelete: isCurrentMonth ? () => onDelete(expense) : null,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _showDetails(BuildContext context, Expense expense) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);
    final category = _categoryFor(expense);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusCard),
        ),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: isCurrentMonth
                    ? IconButton(
                        onPressed: () {
                          Navigator.of(sheetCtx).pop();
                          onEdit(expense);
                        },
                        icon: const Icon(Icons.edit_rounded),
                        iconSize: 20,
                        color: colors.textSecondary,
                        visualDensity: VisualDensity.compact,
                      )
                    : const SizedBox(height: 40),
              ),
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.surfaceBase,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusChip),
                    border: Border.all(color: colors.borderHairline, width: 0.5),
                  ),
                  child: CategoryIcon(
                    category: category,
                    size: 24,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(category.label, style: styles.screenTitle),
              ),
              const SizedBox(height: AppSpacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  obscured
                      ? kObscuredAmount
                      : '₹${expense.amount.toStringAsFixed(2)}',
                  style: styles.totalAmount,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(expense.date),
                  style: styles.cardLabel,
                ),
              ),
              if (expense.note != null && expense.note!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Text(
                    expense.note!,
                    style: styles.body,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Single expense row with category icon, label, note, and amount.
/// Sits directly on the surface base with a 1px hairline divider (§4).
class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.category,
    required this.isEditable,
    this.obscured = false,
    this.onTap,
    this.onDelete,
  });

  final Expense expense;
  final ExpenseCategory category;
  final bool isEditable;
  final bool obscured;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    final row = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.borderHairline, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
              border: Border.all(color: colors.borderHairline, width: 0.5),
            ),
            child: CategoryIcon(
              category: category,
              size: 20,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: styles.listRowTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (expense.note != null && expense.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      expense.note!,
                      style: styles.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            obscured
                ? kObscuredAmount
                : '₹${formatCompactAmount(expense.amount)}',
            style: styles.listRowSecondary,
          ),
        ],
      ),
    );

    if (!isEditable) {
      return GestureDetector(onTap: onTap, child: row);
    }

    return Dismissible(
      key: ValueKey(expense.key ?? expense.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: colors.signalExpense,
        child: Icon(Icons.delete_rounded, color: colors.surfaceRaised),
      ),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete?.call(),
      child: GestureDetector(onTap: onTap, child: row),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: colors.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusCard),
        ),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderHairline,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.signalExpense.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusChip),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: colors.signalExpense,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text('Delete expense?', style: styles.screenTitle),
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '₹${expense.amount.toStringAsFixed(2)}',
                    style: styles.totalAmount,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  "${category.label} · Can't be undone",
                  style: styles.body,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetCtx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.signalExpense,
                    foregroundColor: colors.surfaceRaised,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                    ),
                  ),
                  child: Text('Delete', style: styles.button),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(sheetCtx, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.textPrimary,
                    side: BorderSide(color: colors.borderHairline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                    ),
                  ),
                  child: Text('Cancel', style: styles.listRowTitle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }
}
