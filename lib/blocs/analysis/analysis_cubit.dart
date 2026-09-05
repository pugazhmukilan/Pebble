import 'package:flutter_bloc/flutter_bloc.dart';

import '../../analysis/analysis_calculator.dart';
import '../../analysis/analysis_models.dart';
import '../../data/expense_repository.dart';
import '../../models/date_range.dart';
import '../../models/expense.dart';
import 'analysis_state.dart';

/// Drives the Analysis screen: resolves the selected range, fetches the
/// expenses for it (plus the previous, equally-long window), and computes
/// every derived structure once — widgets never recompute in build().
class AnalysisCubit extends Cubit<AnalysisState> {
  AnalysisCubit(this.repository, {this.calculator = const AnalysisCalculator()})
      : super(const AnalysisInitial());

  final ExpenseRepository repository;
  final AnalysisCalculator calculator;

  AnalysisRangePreset _preset = AnalysisRangePreset.thisMonth;

  /// Selected start/end months for the [AnalysisRangePreset.custom] range.
  DateTime? _customStart;
  DateTime? _customEnd;

  List<Expense>? _allExpenses;

  /// Load (fresh) analysis for the current preset.
  Future<void> load() async {
    emit(const AnalysisLoading());
    try {
      final all = await repository.getAllExpenses();
      _allExpenses = all;
      await _recompute();
    } catch (e) {
      emit(AnalysisError(e.toString()));
    }
  }

  /// Switch to a preset range.
  Future<void> selectRange(AnalysisRangePreset preset) async {
    _preset = preset;
    await load();
  }

  /// Switch to a custom range defined by its start and end months.
  Future<void> selectCustomRange(DateTime start, DateTime end) async {
    _preset = AnalysisRangePreset.custom;
    _customStart = DateTime(start.year, start.month);
    _customEnd = DateTime(end.year, end.month);
    await load();
  }

  Future<void> refresh() => load();

  DateRange _resolveRange() {
    if (_preset == AnalysisRangePreset.custom) {
      final now = DateTime.now();
      final start = _customStart ?? DateTime(now.year, now.month - 2);
      final end = _customEnd ?? DateTime(now.year, now.month);
      return DateRange.range(startMonth: start, endMonth: end);
    }
    return DateRange.monthsFromNow(
      monthCount: _preset.defaultMonths,
      now: DateTime.now(),
    );
  }

  Future<void> _recompute() async {
    final all = _allExpenses ?? await repository.getAllExpenses();

    // Cold start: nothing to analyze until at least two full months of
    // history exist across the whole dataset.
    final distinctMonths = all
        .map((e) => e.date.year * 12 + (e.date.month - 1))
        .toSet();
    if (distinctMonths.length < 2) {
      emit(const AnalysisEmpty());
      return;
    }

    final range = _resolveRange();
    final expenses = await repository.getExpenses(range);
    final categories = await repository.getCategories();

    final monthlyTotals =
        calculator.computeMonthlyTotals(expenses, range);
    final breakdown = calculator.computeCategoryBreakdown(
      expenses,
      categories,
      foldThreshold: 0,
    );

    // Per-category month-over-month deltas — meaningful for any single-month
    // range (the "1M" preset or a custom range narrowed to one month).
    final categoryMonthDeltas = range.monthCount == 1
        ? calculator.computeCategoryMonthDeltas(
            all,
            categories,
            currentMonth: DateTime(range.startYear, range.startMonth),
          )
        : const <CategoryMonthDelta>[];

    // Draw a trend line for every category with spend in the range (capped
    // at the top 10 by amount so the chart stays legible).
    final topIds = breakdown
        .where((s) => s.amount > 0)
        .take(10)
        .map((s) => s.categoryId)
        .toSet();

    final trends = calculator.computeCategoryTrend(
      expenses,
      range,
      categories,
      categoryIds: topIds,
    );

    final currentTotal = monthlyTotals.fold<double>(0, (s, m) => s + m.total);
    final previousExpenses = await repository.getExpenses(range.previousWindow());
    final previousTotal = previousExpenses.fold<double>(0, (s, e) => s + e.amount);
    final comparison = calculator.compareToPreviousRange(
      currentTotal,
      previousTotal,
    );

    final insights = calculator.generateInsights(
      expenses: expenses,
      monthlyTotals: monthlyTotals,
      categories: categories,
    );

emit(
        AnalysisLoaded(
          preset: _preset,
          range: range,
          categories: categories,
          monthlyTotals: monthlyTotals,
          dailyTotals: range.monthCount == 1
              ? calculator.computeDailyTotals(expenses, range)
              : const [],
          categoryBreakdown: breakdown,
          categoryMonthDeltas: categoryMonthDeltas,
          categoryTrendData: trends,
          rangeComparison: comparison,
          insights: insights,
        ),
      );
  }
}