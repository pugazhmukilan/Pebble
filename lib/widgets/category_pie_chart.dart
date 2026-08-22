import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../constants/category_colors.dart';
import '../models/category.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/amount_formatter.dart';
import 'category_icon.dart';

/// Donut-style pie chart showing category breakdown for the month.
/// Uses fl_chart's PieChart with a center hole and a clean legend
/// below.
///
/// Pass [tileLegend] = true to render each legend entry as its own
/// rounded tile (used on the analytics page).
///
/// Category color is used here per §5.3 (slices + legend dots only).
class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({
    super.key,
    required this.categories,
    required this.breakdown,
    required this.total,
    this.obscured = false,
    this.tileLegend = false,
    this.showAll = false,
  });

  final List<ExpenseCategory> categories;
  final Map<String, double> breakdown;
  final double total;
  final bool obscured;
  final bool tileLegend;

  /// When true, every category is drawn (analysis page). When false, only
  /// the top 5 are shown and the rest fold into a single "Other" slice
  /// (compact homepage summary).
  final bool showAll;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    final entries = breakdown.entries.map((entry) {
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => categories.first,
      );
      return _PieEntry(category: category, amount: entry.value);
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    if (entries.isEmpty || total <= 0) return const SizedBox.shrink();

    // Top entries + a single reserved "Other" overflow bucket (§1.3).
    // There is exactly one "Other" — never a separate "Others".
    // When [showAll] is set (analysis page) every category is drawn.
    final visibleEntries = showAll ? entries : entries.take(5).toList();
    if (!showAll) {
      final overflow =
          entries.skip(5).fold<double>(0, (sum, e) => sum + e.amount);
      if (overflow > 0) {
        final existing = visibleEntries.firstWhere(
          (e) => e.category.id == kOtherCategoryId,
          orElse: () {
            final otherCat = categories.firstWhere(
              (c) => c.id == kOtherCategoryId,
              orElse: () => ExpenseCategory(
                id: kOtherCategoryId,
                label: 'Other',
                iconCodePoint: 0,
                colorValue: kOtherColorLight.toARGB32(),
              ),
            );
            final entry = _PieEntry(category: otherCat, amount: 0);
            visibleEntries.add(entry);
            return entry;
          },
        );
        existing.amount += overflow;
      }
    }

    final chartSize = tileLegend ? 180.0 : 140.0;
    final innerRadius = tileLegend ? 46.0 : 34.0;
    final outerRadius = tileLegend ? 66.0 : 50.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: chartSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: innerRadius,
                  startDegreeOffset: -90,
                  sections: entries.map((entry) {
                    final isOther = entry.category.id == kOtherCategoryId;
                    final color = isOther
                        ? colors.categoryOther
                        : resolveCategoryColor(
                            context,
                            entry.category.colorValue,
                          );
                    final pct = entry.amount / total * 100;
                    return PieChartSectionData(
                      value: entry.amount,
                      color: color,
                      radius: outerRadius,
                      title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                      titleStyle: styles.slicePercent,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final entry in visibleEntries)
          tileLegend
              ? _legendTile(context, entry, colors, styles)
              : _legendRow(context, entry, total, colors, styles),
      ],
    );
  }

  Widget _legendTile(
    BuildContext context,
    _PieEntry entry,
    AppColors colors,
    AppTextStyles styles,
  ) {
    final isOther = entry.category.id == kOtherCategoryId;
    final color = isOther
        ? colors.categoryOther
        : resolveCategoryColor(context, entry.category.colorValue);
    final pct = total > 0 ? entry.amount / total * 100 : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      child: Row(
        children: [
          // Neutral icon chip (§4) — category color is NOT applied here.
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surfaceBase,
              borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
              border: Border.all(color: colors.borderHairline, width: 0.5),
            ),
            child: CategoryIcon(
              category: entry.category,
              size: 20,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Colored legend dot beside the category name (§5.3).
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              entry.category.label,
              style: styles.listRowTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                obscured
                    ? kObscuredAmount
                    : '₹${formatCompactAmount(entry.amount)}',
                style: styles.listRowSecondary,
              ),
              const SizedBox(height: 2),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: styles.bodyTertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendRow(
    BuildContext context,
    _PieEntry entry,
    double total,
    AppColors colors,
    AppTextStyles styles,
  ) {
    final isOther = entry.category.id == kOtherCategoryId;
    final color = isOther
        ? colors.categoryOther
        : resolveCategoryColor(context, entry.category.colorValue);
    final pct = total > 0 ? entry.amount / total * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
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
          Text(
            obscured
                ? kObscuredAmount
                : '₹${formatCompactAmount(entry.amount)}',
            style: styles.pieLabel.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          SizedBox(
            width: 36,
            child: Text(
              '${pct.toStringAsFixed(0)}%',
              style: styles.pieLabel,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _PieEntry {
  _PieEntry({required this.category, required this.amount});
  final ExpenseCategory category;
  double amount;
}
