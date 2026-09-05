import 'package:flutter/material.dart';

import '../constants/category_colors.dart';
import '../models/category.dart';
import '../utils/amount_formatter.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
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
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    final entries = breakdown.entries.map((entry) {
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => categories.first,
      );
      return _BarEntry(category: category, amount: entry.value);
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    if (entries.isEmpty) return const SizedBox.shrink();
    final total = entries.fold<double>(0, (sum, e) => sum + e.amount);
    if (total <= 0) return const SizedBox.shrink();

    // Merge anything beyond the top 5 into the single reserved "Other" (§1.3).
    final visible = entries.take(5).toList();
    final overflow =
        entries.skip(5).fold<double>(0, (sum, e) => sum + e.amount);
    if (overflow > 0) {
      final otherCat = categories.firstWhere(
        (c) => c.id == kOtherCategoryId,
        orElse: () => ExpenseCategory(
          id: kOtherCategoryId,
          label: 'Other',
          iconCodePoint: 0,
          colorValue: kOtherColorLight.toARGB32(),
        ),
      );
      visible.add(_BarEntry(category: otherCat, amount: overflow));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: visible
          .map((entry) => _barRow(context, entry, total, colors, styles))
          .toList(),
    );
  }

  Widget _barRow(
    BuildContext context,
    _BarEntry entry,
    double total,
    AppColors colors,
    AppTextStyles styles,
  ) {
    final isOther = entry.category.id == kOtherCategoryId;
    final color = isOther
        ? colors.categoryOther
        : resolveCategoryColor(context, entry.category.colorValue);
    final pct = total > 0 ? entry.amount / total * 100 : 0.0;
    final fraction = (pct / 100).clamp(0.02, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  entry.category.label,
                  style: styles.pieLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              SizedBox(
                width: 44,
                child: Text(
                  formatPercent(pct),
                  style: styles.pieLabel,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          FractionallySizedBox(
            widthFactor: fraction,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
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
