import 'package:flutter/material.dart';

import '../models/category.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/amount_formatter.dart';

class BudgetDetailsSheet extends StatelessWidget {
  const BudgetDetailsSheet({
    super.key,
    required this.category,
    required this.spent,
    required this.limit,
  });

  final ExpenseCategory category;
  final double spent;
  final double limit;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);
    final remaining = limit - spent;
    final isOver = remaining < 0;
    final statusColor = isOver ? colors.signalExpense : colors.signalIncome;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(category.label, style: styles.screenTitle),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: colors.textSecondary,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Budget for this month', style: styles.body),
            const SizedBox(height: 20),
            _BudgetValueRow(
              label: 'Spent',
              value: '₹${formatCompactAmount(spent)}',
              color: colors.textPrimary,
            ),
            const SizedBox(height: 12),
            _BudgetValueRow(
              label: 'Limit',
              value: '₹${formatCompactAmount(limit)}',
              color: colors.textPrimary,
            ),
            const SizedBox(height: 12),
            Divider(color: colors.borderHairline),
            const SizedBox(height: 12),
            _BudgetValueRow(
              label: isOver ? 'Over limit' : 'Left',
              value: isOver
                  ? '₹${formatCompactAmount(remaining.abs())}'
                  : '₹${formatCompactAmount(remaining)}',
              color: statusColor,
              emphasize: true,
            ),
            const SizedBox(height: AppSpacing.s),
          ],
        ),
      ),
    );
  }
}

class _BudgetValueRow extends StatelessWidget {
  const _BudgetValueRow({
    required this.label,
    required this.value,
    required this.color,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final styles = AppTextStyles.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: styles.body)),
        Text(
          value,
          style: styles.body.copyWith(
            color: color,
            fontWeight: emphasize ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
