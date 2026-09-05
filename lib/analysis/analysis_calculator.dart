import '../models/category.dart';
import '../models/date_range.dart';
import '../models/expense.dart';
import '../utils/amount_formatter.dart';
import 'analysis_models.dart';
import 'analysis_thresholds.dart';

/// Pure, deterministic analysis engine.
///
/// No Flutter dependencies — every method is a pure function of its inputs
/// so it can be unit-tested in isolation against hand-built expense lists.
class AnalysisCalculator {
  const AnalysisCalculator();

  /// Display priority of insight kinds (low → high). Top `5` are surfaced.
  static const List<InsightKind> _priorityOrder = [
    InsightKind.spike,
    InsightKind.largestExpense,
    InsightKind.shareShift,
    InsightKind.flatStreak,
    InsightKind.highestMonth,
    InsightKind.newOrDormantCategory,
  ];

  /// One total per calendar month in [range], zero-filled for empty months.
  List<MonthlyTotal> computeMonthlyTotals(
    List<Expense> expenses,
    DateRange range,
  ) {
    final months = range.months;
    final totals = List<double>.filled(months.length, 0);
    for (final expense in expenses) {
      final index = _monthIndex(expense.date, range);
      if (index >= 0 && index < totals.length) {
        totals[index] += expense.amount;
      }
    }
    return [
      for (var i = 0; i < months.length; i++)
        MonthlyTotal(month: months[i], total: totals[i]),
    ];
  }

  /// One total per calendar day in [range], zero-filled.
  ///
  /// Used when the selected range is a single calendar month, where the
  /// trend graph is drawn date-wise instead of month-wise.
  List<DailyTotal> computeDailyTotals(
    List<Expense> expenses,
    DateRange range,
  ) {
    final start = range.start;
    final dayCount = range.endInclusive.difference(start).inDays + 1;
    final totals = List<double>.filled(dayCount, 0);
    for (final expense in expenses) {
      final index = expense.date.difference(start).inDays;
      if (index >= 0 && index < totals.length) {
        totals[index] += expense.amount;
      }
    }
    return [
      for (var i = 0; i < dayCount; i++)
        DailyTotal(day: start.add(Duration(days: i)), total: totals[i]),
    ];
  }

  /// Aggregate category shares across the whole range. Categories under
  /// [foldThreshold]% of spend are folded into a single "Other" slice. Pass
  /// `foldThreshold: 0` to disable folding and surface every category
  /// (used by the analysis page, which must show all categories).
  List<CategoryShare> computeCategoryBreakdown(
    List<Expense> expenses,
    List<ExpenseCategory> categories, {
    double foldThreshold = 3,
  }) {
    final amounts = <String, double>{};
    var total = 0.0;
    for (final e in expenses) {
      amounts[e.categoryId] = (amounts[e.categoryId] ?? 0) + e.amount;
      total += e.amount;
    }
    if (total <= 0) return [];

    final byId = {for (final c in categories) c.id: c};
    final main = <CategoryShare>[];
    var otherAmount = 0.0;
    for (final entry in amounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))) {
      final percent = entry.value / total * 100;
      if (foldThreshold > 0 && percent < foldThreshold) {
        otherAmount += entry.value;
        continue;
      }
      final cat = byId[entry.key];
      main.add(
        CategoryShare(
          categoryId: entry.key,
          label: cat?.label ?? entry.key,
          amount: entry.value,
          percent: percent,
          colorValue: cat?.colorValue ?? 0xFF90A4AE,
        ),
      );
    }
    if (otherAmount > 0) {
      final otherCat = byId['other'];
      main.add(
        CategoryShare(
          categoryId: 'other',
          label: otherCat?.label ?? 'Other',
          amount: otherAmount,
          percent: otherAmount / total * 100,
          colorValue: otherCat?.colorValue ?? 0xFF90A4AE,
        ),
      );
    }
    main.sort((a, b) => b.amount.compareTo(a.amount));
    return main;
  }

  /// Per-month spend series for the given categories, aligned with
  /// `range.months`. Pass the exact set to draw (post "max 3" trimming).
  List<CategoryTrend> computeCategoryTrend(
    List<Expense> expenses,
    DateRange range,
    List<ExpenseCategory> categories, {
    required Set<String> categoryIds,
  }) {
    final byId = {for (final c in categories) c.id: c};
    final trends = <CategoryTrend>[];
    for (final id in categoryIds) {
      final values = List<double>.filled(range.monthCount, 0);
      for (final e in expenses) {
        if (e.categoryId != id) continue;
        final index = _monthIndex(e.date, range);
        if (index >= 0 && index < values.length) values[index] += e.amount;
      }
      final cat = byId[id];
      trends.add(
        CategoryTrend(
          categoryId: id,
          label: cat?.label ?? id,
          colorValue: cat?.colorValue ?? 0xFF90A4AE,
          values: values,
        ),
      );
    }
    return trends;
  }

  /// Compare spend in the selected range against the equally-long window
  /// immediately before it. No ∞%: [percentChange] is null when the
  /// previous window had no spend.
  RangeComparison compareToPreviousRange(
    double currentTotal,
    double previousTotal,
  ) {
    final difference = currentTotal - previousTotal;
    return RangeComparison(
      currentTotal: currentTotal,
      previousTotal: previousTotal,
      difference: difference,
      percentChange: previousTotal != 0 ? difference / previousTotal : null,
    );
  }

  /// Per-category month-over-month change for the [currentMonth] view.
  ///
  /// Each delta is aligned with the current month's [computeCategoryBreakdown]
  /// (so sub-3% categories are folded into the same "Other" bucket as the
  /// pie), and compares that category's spend this month against the previous
  /// calendar month. No ∞%: [percentChange] is null when there was no spend
  /// last month.
  List<CategoryMonthDelta> computeCategoryMonthDeltas(
    List<Expense> expenses,
    List<ExpenseCategory> categories, {
    required DateTime currentMonth,
  }) {
    final prevMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    final currentExpenses = expenses
        .where((e) =>
            e.date.year == currentMonth.year &&
            e.date.month == currentMonth.month)
        .toList();
    final prevExpenses = expenses
        .where((e) =>
            e.date.year == prevMonth.year && e.date.month == prevMonth.month)
        .toList();

    final currentBreakdown = computeCategoryBreakdown(
      currentExpenses,
      categories,
      foldThreshold: 0,
    );
    final prevBreakdown = computeCategoryBreakdown(
      prevExpenses,
      categories,
      foldThreshold: 0,
    );
    final prevBy = {for (final s in prevBreakdown) s.categoryId: s.amount};

    return [
      for (final share in currentBreakdown)
        CategoryMonthDelta(
          categoryId: share.categoryId,
          label: share.label,
          colorValue: share.colorValue,
          currentAmount: share.amount,
          previousAmount: prevBy[share.categoryId] ?? 0,
          difference: share.amount - (prevBy[share.categoryId] ?? 0),
          percentChange: (prevBy[share.categoryId] ?? 0) != 0
              ? (share.amount - (prevBy[share.categoryId] ?? 0)) /
                  (prevBy[share.categoryId] ?? 0) *
                  100
              : null,
        ),
    ];
  }

  /// Deterministic insights, ordered by [_priorityOrder], capped at 5.
  /// Returns an empty list when there isn't enough history so the UI can
  /// hide the whole section.
  List<Insight> generateInsights({
    required List<Expense> expenses,
    required List<MonthlyTotal> monthlyTotals,
    required List<ExpenseCategory> categories,
  }) {
    if (monthlyTotals.length < 2) return [];

    final insights = <Insight>[];
    final byId = {for (final c in categories) c.id: c};
    final avg = monthlyTotals.fold<double>(0, (s, m) => s + m.total) /
        monthlyTotals.length;

    // Spike — a month well above the average (30% and at least ₹500).
    if (avg > 0) {
      final spikes = monthlyTotals
          .where(
            (m) =>
                m.total > avg * (1 + kInsightSpikeThreshold) &&
                (m.total - avg) >= kInsightLargestMin,
          )
          .toList()
        ..sort((a, b) => b.total.compareTo(a.total));
      if (spikes.isNotEmpty) {
        final spike = spikes.first;
        final pct = ((spike.total / avg) - 1) * 100;
        insights.add(
          Insight(
            kind: InsightKind.spike,
            title: '${_monthName(spike.month)} spiked ${formatPercent(pct)} above average',
            body: '₹${formatCompactAmount(spike.total)} vs a ₹${formatCompactAmount(avg)} monthly average',
          ),
        );
      }
    }

    // Largest single expense in the range.
    Expense? largest;
    for (final e in expenses) {
      if (largest == null || e.amount > largest.amount) largest = e;
    }
    if (largest != null && largest.amount >= kInsightLargestMin) {
      insights.add(
        Insight(
          kind: InsightKind.largestExpense,
          title: 'Largest single expense: ₹${formatCompactAmount(largest.amount)}',
          body: byId[largest.categoryId]?.label ?? largest.categoryId,
        ),
      );
    }

    // Share shift — a category whose share of monthly spend moved by at
    // least 10pp between the last two months.
    if (monthlyTotals.length >= 2) {
      final last = monthlyTotals[monthlyTotals.length - 1];
      final prev = monthlyTotals[monthlyTotals.length - 2];
      if (prev.total > 0 && last.total > 0) {
        final prevAgg = _aggregateForMonth(expenses, prev.month);
        final lastAgg = _aggregateForMonth(expenses, last.month);
        final ids = {...prevAgg.keys, ...lastAgg.keys}.toList()..sort();
        for (final id in ids) {
          final change =
              ((lastAgg[id] ?? 0) / last.total -
                      (prevAgg[id] ?? 0) / prev.total) *
                  100;
          if (change.abs() >= kInsightShareShiftPp) {
            final direction = change > 0 ? 'rose' : 'fell';
            insights.add(
              Insight(
                kind: InsightKind.shareShift,
                title: '${byId[id]?.label ?? id} share $direction ${change.abs().round()}pp',
                body: '${_monthName(prev.month)} → ${_monthName(last.month)}',
              ),
            );
            break;
          }
        }
      }
    }

    // Flat streak — 3+ consecutive months within ±5% of the average.
    if (avg > 0) {
      final band = avg * kInsightFlatBand;
      var bestStart = -1, bestLen = 0, runStart = -1, runLen = 0;
      for (var i = 0; i < monthlyTotals.length; i++) {
        final within = (monthlyTotals[i].total - avg).abs() <= band;
        if (within) {
          if (runStart < 0) runStart = i;
          runLen++;
          if (runLen > bestLen) {
            bestLen = runLen;
            bestStart = runStart;
          }
        } else {
          runStart = -1;
          runLen = 0;
        }
      }
      if (bestLen >= 3) {
        final from = monthlyTotals[bestStart];
        final to = monthlyTotals[bestStart + bestLen - 1];
        insights.add(
          Insight(
            kind: InsightKind.flatStreak,
            title: '$bestLen months stayed within ±5% of your average',
            body: '${_monthName(from.month)} → ${_monthName(to.month)}',
          ),
        );
      }
    }

    // Highest-spend month in the range.
    if (monthlyTotals.length >= 2) {
      var max = monthlyTotals.first;
      for (final m in monthlyTotals) {
        if (m.total > max.total) max = m;
      }
      if (max.total > 0) {
        insights.add(
          Insight(
            kind: InsightKind.highestMonth,
            title: '${_monthName(max.month)} was your highest-spend month',
            body: '₹${formatCompactAmount(max.total)} total',
          ),
        );
      }
    }

    // New or dormant category — activity change between the last two months.
    if (monthlyTotals.length >= 2) {
      final last = monthlyTotals[monthlyTotals.length - 1];
      final prev = monthlyTotals[monthlyTotals.length - 2];
      final prevAgg = _aggregateForMonth(expenses, prev.month);
      final lastAgg = _aggregateForMonth(expenses, last.month);
      final newCats = lastAgg.keys
          .where((id) => (prevAgg[id] ?? 0) == 0)
          .toList()
        ..sort();
      final dormant = prevAgg.keys
          .where((id) => (lastAgg[id] ?? 0) == 0)
          .toList()
        ..sort();
      if (newCats.isNotEmpty) {
        final id = newCats.first;
        insights.add(
          Insight(
            kind: InsightKind.newOrDormantCategory,
            title: '${byId[id]?.label ?? id} appeared this month',
            body: 'first spend in ${_monthName(last.month)}',
          ),
        );
      } else if (dormant.isNotEmpty) {
        final id = dormant.first;
        insights.add(
          Insight(
            kind: InsightKind.newOrDormantCategory,
            title: 'No spend on ${byId[id]?.label ?? id} this month',
            body: 'inactive in ${_monthName(last.month)}',
          ),
        );
      }
    }

    insights.sort(
      (a, b) => _priorityOrder
          .indexOf(a.kind)
          .compareTo(_priorityOrder.indexOf(b.kind)),
    );
    return insights.take(5).toList();
  }

  Map<String, double> _aggregateForMonth(
    List<Expense> expenses,
    DateTime month,
  ) {
    final agg = <String, double>{};
    for (final e in expenses) {
      if (e.date.year == month.year && e.date.month == month.month) {
        agg[e.categoryId] = (agg[e.categoryId] ?? 0) + e.amount;
      }
    }
    return agg;
  }

  int _monthIndex(DateTime date, DateRange range) {
    if (!range.containsMonth(date.year, date.month)) return -1;
    return (date.year - range.startYear) * 12 +
        (date.month - range.startMonth);
  }

  static const _monthShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _monthName(DateTime month) => '${_monthShort[month.month - 1]} ${month.year}';
}