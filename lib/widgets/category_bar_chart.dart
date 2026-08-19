import 'package:flutter/material.dart';

import '../models/category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Horizontal bar (linear) chart of the selected month's category breakdown.
/// Top categories are listed with a proportion bar, amount, and share %.
class CategoryBarChart extends StatelessWidget {
  const CategoryBarChart({
    super.key,
    required this.categories,
    required this.breakdown,
  });

  final List<ExpenseCategory> categories;
  final Map<String, double> breakdown;

  @override
  Widget build(BuildContext context) {
    final entries = breakdown.entries.map((entry) {
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => categories.first,
      );
      return _BarEntry(category: category, amount: entry.value);
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

    if (entries.isEmpty) return const SizedBox.shrink();
    final total = entries.fold<double>(0, (sum, e) => sum + e.amount);
    if (total <= 0) return const SizedBox.shrink();

    final visible = entries.take(5).toList();
    final others = entries.skip(5);
    final othersTotal = others.fold<double>(0, (sum, e) => sum + e.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...visible.map((entry) => _barRow(entry, total)),
        if (others.isNotEmpty)
          _barRow(
            _BarEntry(
              category: ExpenseCategory(
                id: '__others__',
                label: 'Others',
                iconCodePoint: 0,
                colorValue: AppColors.textMuted.toARGB32(),
              ),
              amount: othersTotal,
            ),
            total,
          ),
      ],
    );
  }

  Widget _barRow(_BarEntry entry, double total) {
    final color = Color(entry.category.colorValue);
    final pct = total > 0 ? entry.amount / total * 100 : 0.0;
    final fraction = (pct / 100).clamp(0.02, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
          const SizedBox(height: 6),
          FractionallySizedBox(
            widthFactor: fraction,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarEntry {
  const _BarEntry({required this.category, required this.amount});
  final ExpenseCategory category;
  final double amount;
}
