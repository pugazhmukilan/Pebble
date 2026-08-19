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
    this.lastExportDate,
  });

  final double total;
  final Map<String, double> categoryBreakdown;
  final List<ExpenseCategory> categories;
  final DateTime? lastExportDate;

  String get _backupLabel {
    if (lastExportDate == null) return 'No backup yet';
    final days = DateTime.now().difference(lastExportDate!).inDays;
    if (days == 0) return 'Backed up today';
    if (days == 1) return 'Last backup: 1 day ago';
    return 'Last backup: $days days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Total spent', style: AppTextStyles.cardLabel),
              const Spacer(),
              Text(_backupLabel, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '₹${formatCompactAmount(total)}',
              style: AppTextStyles.totalAmount,
            ),
          ),
          if (categoryBreakdown.isNotEmpty && total > 0) ...[
            const SizedBox(height: 20),
            CategoryPieChart(
              categories: categories,
              breakdown: categoryBreakdown,
              total: total,
            ),
          ],
        ],
      ),
    );
  }
}
