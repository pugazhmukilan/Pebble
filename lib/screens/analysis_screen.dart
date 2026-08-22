import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/analysis/analysis_cubit.dart';
import '../blocs/analysis/analysis_state.dart';
import '../analysis/analysis_models.dart';
import '../constants/category_colors.dart';
import '../data/expense_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/amount_formatter.dart';
import '../widgets/category_pie_chart.dart';

/// Analysis page: hero trend card (range tabs, compact total + average,
/// interactive line chart with labelled x/y axes and a dashed average line).
class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AnalysisCubit(context.read<ExpenseRepository>())..load(),
      child: Scaffold(
        backgroundColor: AppColors.of(context).surfaceBase,
        appBar: AppBar(
          title: Text('Analysis', style: AppTextStyles.of(context).screenTitle),
          centerTitle: true,
        ),
        body: BlocBuilder<AnalysisCubit, AnalysisState>(
          builder: (context, state) {
            if (state is AnalysisLoading || state is AnalysisInitial) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppColors.of(context).textPrimary,
                ),
              );
            }
            if (state is AnalysisEmpty) {
              return _NotEnoughData();
            }
            if (state is AnalysisError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Something went wrong: ${state.message}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.of(context).cardLabel,
                  ),
                ),
              );
            }
            return _AnalysisBody(state: state as AnalysisLoaded);
          },
        ),
      ),
    );
  }
}

class _NotEnoughData extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: colors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Not enough data yet',
              style: styles.screenTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Analysis becomes useful after your second month.',
              style: styles.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisBody extends StatelessWidget {
  const _AnalysisBody({required this.state});

  final AnalysisLoaded state;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: state.preset == AnalysisRangePreset.thisMonth
                ? _ThisMonthView(state: state)
                : _HeroTrendCard(state: state),
          ),
        ),
      ],
    );
  }
}

/// Shared "Category Breakdown" block: section header + donut/legend. Used by
/// both the trend view and the single-month view so they stay consistent.
class _CategoryBreakdownSection extends StatelessWidget {
  const _CategoryBreakdownSection({required this.state});

  final AnalysisLoaded state;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);
    final breakdown = state.categoryBreakdown;
    if (breakdown.isEmpty) return const SizedBox.shrink();
    final total = breakdown.fold<double>(0, (s, c) => s + c.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 20,
              decoration: BoxDecoration(
                color: colors.textPrimary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            const SizedBox(width: 10),
            Text('Category Breakdown', style: styles.screenTitle),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        CategoryPieChart(
          categories: state.categories,
          breakdown: {
            for (final share in breakdown) share.categoryId: share.amount,
          },
          total: total,
          tileLegend: true,
          showAll: true,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single-month view (1M tab): no top trend graph. Shows the month total +
// overall change vs last month, the category donut, and a per-category
// month-over-month increase/decrease list.
// ─────────────────────────────────────────────────────────────────────────────

class _ThisMonthView extends StatelessWidget {
  const _ThisMonthView({required this.state});

  final AnalysisLoaded state;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    final now = DateTime.now();
    final breakdown = state.categoryBreakdown;
    final total = breakdown.fold<double>(0, (s, c) => s + c.amount);
    final comparison = state.rangeComparison;

    final children = <Widget>[
      // Range switcher so the user can leave this view.
      _RangeTabs(state: state),
      const SizedBox(height: 16),
      // This month total + overall change vs last month.
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceBase,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border:
                        Border.all(color: colors.borderHairline, width: 0.5),
                  ),
                  child: Text(
                    _monthName(now),
                    style: styles.chipLabel
                        .copyWith(color: colors.textSecondary),
                  ),
                ),
                const Spacer(),
                _DeltaBadge(
                  difference: comparison.difference,
                  colors: colors,
                  styles: styles,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Spent this month', style: styles.cardLabel),
            const SizedBox(height: 2),
            Text(
              '₹${formatFullAmount(total)}',
              style: styles.screenTitle,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      _CategoryBreakdownSection(state: state),
      const SizedBox(height: AppSpacing.lg),
      _CategoryDeltaList(state: state),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// Per-category increase/decrease compared with the previous calendar month.
class _CategoryDeltaList extends StatelessWidget {
  const _CategoryDeltaList({required this.state});

  final AnalysisLoaded state;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);
    final deltas = state.categoryMonthDeltas;
    if (deltas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 5,
              height: 20,
              decoration: BoxDecoration(
                color: colors.textPrimary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
            const SizedBox(width: 10),
            Text('vs Last Month', style: styles.screenTitle),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (final delta in deltas) _deltaTile(context, delta, colors, styles),
      ],
    );
  }

  Widget _deltaTile(
    BuildContext context,
    CategoryMonthDelta delta,
    AppColors colors,
    AppTextStyles styles,
  ) {
    final isOther = delta.categoryId == kOtherCategoryId;
    final dotColor = isOther
        ? colors.categoryOther
        : resolveCategoryColor(context, delta.colorValue);
    final up = delta.difference >= 0;
    final signal = up ? colors.signalExpense : colors.signalIncome;

    final pctText = delta.percentChange == null
        ? 'new'
        : '${delta.percentChange! >= 0 ? '+' : ''}${delta.percentChange!.toStringAsFixed(0)}%';
    final diffText =
        '${delta.difference >= 0 ? '+' : '−'}₹${formatFullAmount(delta.difference.abs())}';

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
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              delta.label,
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
                '₹${formatFullAmount(delta.currentAmount)}',
                style: styles.listRowSecondary,
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    up
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 12,
                    color: signal,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    pctText,
                    style: styles.bodyTertiary.copyWith(
                      color: signal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    diffText,
                    style: styles.bodyTertiary.copyWith(color: signal),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact pill showing the overall month-over-month change.
class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({
    required this.difference,
    required this.colors,
    required this.styles,
  });

  final double difference;
  final AppColors colors;
  final AppTextStyles styles;

  @override
  Widget build(BuildContext context) {
    final up = difference >= 0;
    final signal = up ? colors.signalExpense : colors.signalIncome;
    final diffText =
        '${difference >= 0 ? '+' : '−'}₹${formatFullAmount(difference.abs())}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 14,
          color: signal,
        ),
        const SizedBox(width: 4),
        Text(
          diffText,
          style: styles.chipLabel.copyWith(
            color: signal,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero trend card
// ─────────────────────────────────────────────────────────────────────────────

class _HeroTrendCard extends StatefulWidget {
  const _HeroTrendCard({required this.state});

  final AnalysisLoaded state;

  @override
  State<_HeroTrendCard> createState() => _HeroTrendCardState();
}

class _HeroTrendCardState extends State<_HeroTrendCard> {
  /// Index of the month highlighted by the last tap; null = nothing
  /// focused.
  int? _focused;

  @override
  void didUpdateWidget(covariant _HeroTrendCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new range replaces the whole dataset → drop any focus.
    if (oldWidget.state.range != widget.state.range) {
      _focused = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    final totals = widget.state.monthlyTotals;
    if (totals.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    // Only plot months up to now so future slots don't drag the line to 0.
    var plotted = totals.indexWhere(
      (m) => _isFutureMonth(m.month, currentMonth),
    );
    if (plotted == -1) plotted = totals.length;

    final spots = <FlSpot>[
      for (var i = 0; i < plotted; i++) FlSpot(i.toDouble(), totals[i].total),
    ];

    final maxValue = totals.fold<double>(
      0,
      (s, m) => m.total > s ? m.total : s,
    );
    // Round the Y axis up to a "nice" step so the line fills the plot area.
    final interval = _niceInterval(maxValue);
    final maxY = (maxValue / interval).ceilToDouble() * interval;
    final safeMaxY = maxY <= 0 ? 1.0 : maxY;

    // Range total + monthly average across elapsed months only.
    final rangeTotal = totals.fold<double>(0, (s, m) => s + m.total);
    final elapsedTotal = totals
        .take(plotted)
        .fold<double>(0, (s, m) => s + m.total);
    final average = plotted == 0 ? 0.0 : elapsedTotal / plotted;

final children = <Widget>[
      // Segmented range control — single source of truth for range.
      _RangeTabs(state: widget.state),
      const SizedBox(height: 16),
      // Compact summary row: range total + per-month average.
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total', style: styles.cardLabel),
              const SizedBox(height: 2),
              Text(
                '₹${formatFullAmount(rangeTotal)}',
                style: styles.screenTitle,
              ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Avg / month', style: styles.caption),
                const SizedBox(height: 2),
                Text(
                  '₹${formatFullAmount(average)}',
                  style: styles.cardLabel.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      // Interactive line chart with labelled x/y axes.
      SizedBox(
        height: 210,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: totals.length > 1 ? (totals.length - 1).toDouble() : 1.0,
            minY: 0,
            maxY: safeMaxY,
            clipData: const FlClipData.all(),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.25,
                preventCurveOverShooting: true,
                barWidth: 2,
                color: colors.textPrimary,
                isStrokeCapRound: true,
                belowBarData: BarAreaData(
                  show: true,
                  color: colors.textPrimary.withValues(alpha: 0.06),
                ),
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: index == _focused ? 5 : 3,
                    color: colors.textPrimary,
                    strokeWidth: 0,
                  ),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: interval,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      formatCompactAmount(value),
                      textAlign: TextAlign.right,
                      style: styles.caption,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  interval: totals.length > 7 ? 3 : 1,
                  getTitlesWidget: (value, meta) =>
                      _xAxisLabel(context, value.toInt()),
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: colors.borderHairline, strokeWidth: 0.5),
            ),
            extraLinesData: average > 0
                ? ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: average,
                        color: colors.textSecondary.withValues(alpha: 0.5),
                        strokeWidth: 1,
                        dashArray: [5, 4],
                      ),
                    ],
                  )
                : const ExtraLinesData(),
            borderData: FlBorderData(
              show: true,
              border: Border(
                left: BorderSide(color: colors.borderHairline),
                bottom: BorderSide(color: colors.borderHairline),
              ),
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => colors.textPrimary,
                getTooltipItems: (touchedSpots) => [
                  for (final s in touchedSpots)
                    LineTooltipItem(
                      '${_monthShorts[totals[s.x.round()].month.month - 1]}'
                      ' · ₹${formatFullAmount(s.y)}',
                      TextStyle(
                        color: colors.surfaceRaised,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
              touchCallback: (event, response) {
                if (event is FlTapUpEvent &&
                    response?.lineBarSpots != null &&
                    response!.lineBarSpots!.isNotEmpty) {
                  final index = response.lineBarSpots!.first.spotIndex;
                  if (index >= 0 &&
                      index < totals.length &&
                      index != _focused) {
                    setState(() => _focused = index);
                  }
                }
              },
            ),
          ),
        ),
      ),
    ];

    // Category split across the whole selected range — same donut +
    // legend (name · amount · %) as the home screen.
    if (widget.state.categoryBreakdown.isNotEmpty && rangeTotal > 0) {
      children.add(const SizedBox(height: 24));
      children.add(_CategoryBreakdownSection(state: widget.state));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  /// Bottom-axis label for month at [index]; the focused month gets an
  /// accent pill.
  Widget _xAxisLabel(BuildContext context, int index) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);
    final totals = widget.state.monthlyTotals;
    if (index < 0 || index >= totals.length) {
      return const SizedBox.shrink();
    }
    final label = _monthShorts[totals[index].month.month - 1].toUpperCase();
    if (index != _focused) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(label, style: styles.caption),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: colors.textPrimary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        ),
        child: Text(
          label,
          style: styles.caption.copyWith(
            color: colors.surfaceRaised,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// The segmented pill range control (`3M | 6M | 1Y`). This is the page's
/// single range selector.
class _RangeTabs extends StatelessWidget {
  const _RangeTabs({required this.state});

  final AnalysisLoaded state;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderHairline, width: 0.5),
      ),
      child: Row(
        children: [
          for (final preset in AnalysisRangePreset.values) ...[
            Expanded(child: _tab(context, preset)),
            if (preset != AnalysisRangePreset.values.last)
              const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, AnalysisRangePreset preset) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);
    final selected = state.preset == preset;
    return GestureDetector(
      onTap: () => context.read<AnalysisCubit>().selectRange(preset),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? colors.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          preset.label,
          textAlign: TextAlign.center,
          style: styles.chipLabel.copyWith(
            color: selected ? colors.surfaceRaised : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

bool _isFutureMonth(DateTime month, DateTime currentMonth) =>
    month.isAfter(currentMonth);

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

const _monthShorts = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "August 2026" style label for a month.
String _monthName(DateTime month) =>
    '${_monthShorts[month.month - 1]} ${month.year}';

/// A "nice" interval for gridlines / y-axis steps.
double _niceInterval(double value) {
  if (value <= 0) return 1;
  final magnitude = _pow10(value.toStringAsFixed(0).length);
  return value / magnitude * 10 >= 5 ? magnitude * 0.5 : magnitude * 0.2;
}

double _pow10(int exponent) {
  var result = 1.0;
  for (var i = 0; i < exponent - 1; i++) {
    result *= 10;
  }
  return result;
}
