import 'package:flutter/material.dart';

import '../models/category.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
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
    this.previousMonthTotal = 0,
    this.lastExportDate,
    this.obscured = false,
    this.onToggleObscured,
  });

  final double total;
  final Map<String, double> categoryBreakdown;
  final List<ExpenseCategory> categories;
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        border: Border.all(color: colors.borderHairline, width: 0.5),
      ),
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
                            fontFeatures: [
                              FontFeature.tabularFigures(),
                            ],
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
        ],
      ),
    );
  }
}