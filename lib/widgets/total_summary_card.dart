import 'package:flutter/material.dart';

import '../models/category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/amount_formatter.dart';
import 'category_pie_chart.dart';

/// Total amount card with backup-age indicator and the category breakdown
/// pie chart + bar chart.
class TotalSummaryCard extends StatelessWidget {
  const TotalSummaryCard({
    super.key,
    required this.total,
    required this.categoryBreakdown,
    required this.categories,
    this.categoryLimits = const {},
    this.onBudgetTap,
    this.previousMonthTotal = 0,
    this.lastExportDate,
    this.obscured = false,
    this.onToggleObscured,
  });

  final double total;
  final Map<String, double> categoryBreakdown;
  final List<ExpenseCategory> categories;
  final Map<String, double> categoryLimits;
  final void Function(ExpenseCategory category, double spent, double limit)?
  onBudgetTap;

  /// Total spent in the month before the selected month — baseline for the
  /// compact up/down delta ticker rendered beside the total.
  final double previousMonthTotal;
  final DateTime? lastExportDate;
  final bool obscured;
  final VoidCallback? onToggleObscured;

  String get _backupLabel {
    if (lastExportDate == null) return 'No backup yet';
    final days = DateTime.now().difference(lastExportDate!).inDays;
    if (days == 0) return 'Backed up today';
    if (days == 1) return 'Last backup: 1 day ago';
    return 'Last backup: $days days ago';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    final delta = total - previousMonthTotal;
    final deltaColor = delta > 0 ? colors.signalExpense : colors.signalIncome;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Total spent', style: styles.cardLabel),
              const Spacer(),
              Text(_backupLabel, style: styles.caption),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        obscured
                            ? kObscuredAmount
                            : '₹${formatFullAmount(total)}',
                        style: styles.totalAmount,
                      ),
                      // Compact stock-ticker delta right next to the number
                      // (baseline-aligned): a filled triangle + compact amount.
                      if (delta != 0) ...[
                        const SizedBox(width: 7),
                        Text(
                          delta > 0 ? '▲' : '▼',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: deltaColor,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          obscured
                              ? kObscuredAmount
                              : formatCompactAmount(delta.abs()),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: deltaColor,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (onToggleObscured != null) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: obscured ? 'Show amounts' : 'Hide amounts',
                  child: InkWell(
                    onTap: onToggleObscured,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        obscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 22,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (categoryBreakdown.isNotEmpty && total > 0) ...[
            const SizedBox(height: 20),
            CategoryPieChart(
              categories: categories,
              breakdown: categoryBreakdown,
              total: total,
              obscured: obscured,
            ),
          ],
          if (categoryLimits.isNotEmpty) ...[
            if (categoryBreakdown.isNotEmpty && total > 0)
              const SizedBox(height: 20),
            _CategoryLimitsSummary(
              categories: categories,
              spentByCategory: categoryBreakdown,
              limits: categoryLimits,
              obscured: obscured,
              onBudgetTap: onBudgetTap,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Budget chip grid ─────────────────────────────────────────────────────────
//
// Design reference: Linear's issue-count chips + Datadog's metric cards.
//
// Each chip is a small card with:
//   • A traffic-light status dot
//   • Category name (truncated)
//   • Remaining budget, or the negative over-limit amount
//
// Chips render in a compact, non-scrolling 2-column grid.

class _CategoryLimitsSummary extends StatelessWidget {
  const _CategoryLimitsSummary({
    required this.categories,
    required this.spentByCategory,
    required this.limits,
    required this.obscured,
    this.onBudgetTap,
  });

  final List<ExpenseCategory> categories;
  final Map<String, double> spentByCategory;
  final Map<String, double> limits;
  final bool obscured;
  final void Function(ExpenseCategory category, double spent, double limit)?
  onBudgetTap;

  @override
  Widget build(BuildContext context) {
    final styles = AppTextStyles.of(context);
    final limitedCategories = categories
        .where(
          (c) => limits.containsKey(c.id) && (spentByCategory[c.id] ?? 0) > 0,
        )
        .toList();

    if (limitedCategories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Budget', style: styles.cardLabel),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: limitedCategories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: 60,
          ),
          itemBuilder: (context, index) {
            final cat = limitedCategories[index];
            return _BudgetChip(
              category: cat,
              spent: spentByCategory[cat.id] ?? 0,
              limit: limits[cat.id]!,
              obscured: obscured,
              onTap: onBudgetTap == null
                  ? null
                  : () => onBudgetTap!(
                      cat,
                      spentByCategory[cat.id] ?? 0,
                      limits[cat.id]!,
                    ),
            );
          },
        ),
      ],
    );
  }
}

/// Status tier based on spending ratio (0–1).
enum _StatusTier { safe, warning, over }

_StatusTier _tier(double ratio) {
  if (ratio >= 1.0) return _StatusTier.over;
  if (ratio >= 0.8) return _StatusTier.warning;
  return _StatusTier.safe;
}

/// A compact budget chip rendered inside the 2-column grid.
///
/// Layout:
///   [name]                         [trend arrow]
///   [amount left / over-limit amount]
class _BudgetChip extends StatelessWidget {
  const _BudgetChip({
    required this.category,
    required this.spent,
    required this.limit,
    required this.obscured,
    this.onTap,
  });

  final ExpenseCategory category;
  final double spent;
  final double limit;
  final bool obscured;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    final ratio = limit > 0 ? (spent / limit).clamp(0.0, 2.0) : 0.0;
    final tier = _tier(ratio);

    final remaining = limit - spent;
    final remainingLabel = obscured
        ? kObscuredAmount
        : remaining < 0
        ? '-₹${formatCompactAmount(remaining.abs())} over'
        : '₹${formatCompactAmount(remaining)} left';

    return Material(
      color: colors.surfaceRaised,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderHairline, width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          category.label,
                          style: styles.body.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          remainingLabel,
                          style: styles.body.copyWith(
                            color: tier == _StatusTier.over
                                ? colors.signalExpense
                                : colors.signalIncome,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            letterSpacing: 0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    tier == _StatusTier.over
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 20,
                    color: tier == _StatusTier.over
                        ? colors.signalExpense
                        : colors.signalIncome,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
