import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category.dart';
import '../models/expense.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/amount_formatter.dart';
import 'category_icon.dart';

/// Expense list grouped by day, most recent first.
/// Tap a row → details with edit. Swipe → delete, both gated by
/// isCurrentMonth (§8).
class ExpenseList extends StatelessWidget {
  const ExpenseList({
    super.key,
    required this.expenses,
    required this.categories,
    required this.isCurrentMonth,
    required this.onDelete,
    required this.onEdit,
  });

  final List<Expense> expenses;
  final List<ExpenseCategory> categories;
  final bool isCurrentMonth;
  final void Function(Expense) onDelete;
  final void Function(Expense) onEdit;

  /// Group expenses by day (date only, no time).
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
    if (expenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: AppColors.accentDisabled,
              ),
              SizedBox(height: 12),
              Text('No expenses this month', style: AppTextStyles.cardLabel),
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
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(
                label.toUpperCase(),
                style: AppTextStyles.sectionHeader,
              ),
            ),
            ...dayExpenses.map(
              (expense) => _ExpenseRow(
                expense: expense,
                category: _categoryFor(expense),
                isEditable: isCurrentMonth,
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
    final category = _categoryFor(expense);
    final color = Color(category.colorValue);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: CategoryIcon(
                    category: category,
                    size: 24,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(category.label, style: AppTextStyles.monthHeader),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '₹${expense.amount.toStringAsFixed(2)}',
                  style: AppTextStyles.totalAmount,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(expense.date),
                  style: AppTextStyles.cardLabel,
                ),
              ),
              if (expense.note != null && expense.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    expense.note!,
                    style: AppTextStyles.expenseNote,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (isCurrentMonth)
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetCtx).pop();
                      onEdit(expense);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit expense'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single expense row with category icon, label, note, and amount.
class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.category,
    required this.isEditable,
    this.onTap,
    this.onDelete,
  });

  final Expense expense;
  final ExpenseCategory category;
  final bool isEditable;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);

    final row = Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CategoryIcon(category: category, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          // Label + note
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: AppTextStyles.expenseLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (expense.note != null && expense.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      expense.note!,
                      style: AppTextStyles.expenseNote,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Amount — compact when large so the label keeps its space
          Text(
            '₹${formatCompactAmount(expense.amount)}',
            style: AppTextStyles.expenseAmount,
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
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 1),
        decoration: BoxDecoration(
          color: AppColors.destructive,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete expense?'),
            content: const Text('This action cannot be undone.'),
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
      },
      onDismissed: (_) => onDelete?.call(),
      child: GestureDetector(onTap: onTap, child: row),
    );
  }
}
