import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/amount_formatter.dart';

/// Donut-style pie chart showing category breakdown for the month.
/// Uses fl_chart's PieChart with a center hole and legend below.
class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({
    super.key,
    required this.categories,
    required this.breakdown,
    required this.total,
  });

  final List<ExpenseCategory> categories;
  final Map<String, double> breakdown;
  final double total;

  @override
  Widget build(BuildContext context) {
    final entries = breakdown.entries.map((entry) {
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => categories.first,
      );
      return _PieEntry(category: category, amount: entry.value);
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    if (entries.isEmpty || total <= 0) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 170,
          child: Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 48,
                  sections: entries.map((entry) {
                    final color = Color(entry.category.colorValue);
                    final pct = entry.amount / total * 100;
                    return PieChartSectionData(
                      value: entry.amount,
                      color: color,
                      radius: 28,
                      title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                      titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        ...entries.take(5).map((entry) => _legendRow(entry, total)),
        if (entries.length > 5)
          _legendRow(
            _PieEntry(
              category: ExpenseCategory(
                id: '__others__',
                label: 'Others',
                iconCodePoint: 0,
                colorValue: AppColors.textMuted.toARGB32(),
              ),
              amount: entries.skip(5).fold<double>(
                    0,
                    (sum, e) => sum + e.amount,
                  ),
            ),
            total,
          ),
      ],
    );
  }

  Widget _legendRow(_PieEntry entry, double total) {
    final color = Color(entry.category.colorValue);
    final pct = total > 0 ? entry.amount / total * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.category.label,
              style: AppTextStyles.pieLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${formatCompactAmount(entry.amount)}',
            style: AppTextStyles.pieLabel.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '${pct.toStringAsFixed(0)}%',
              style: AppTextStyles.pieLabel,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _PieEntry {
  const _PieEntry({required this.category, required this.amount});
  final ExpenseCategory category;
  final double amount;
}
