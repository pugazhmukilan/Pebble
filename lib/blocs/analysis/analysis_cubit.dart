import 'package:flutter_bloc/flutter_bloc.dart';

import '../../analysis/analysis_calculator.dart';
import '../../analysis/analysis_models.dart';
import '../../data/expense_repository.dart';
import '../../models/category.dart';
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

  /// Category ids pinned for the per-category trend (max 3).
  final List<String> _pinned = [];

  List<Expense>? _allExpenses;
  DateRange? _lastRange;
  List<Expense>? _lastExpenses;
  List<ExpenseCategory>? _lastCategories;

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

  /// Pin / unpin a category for the per-category trend chart (max 3).
  Future<void> toggleCategoryForTrend(String categoryId) async {
    final loaded = state;
    if (loaded is! AnalysisLoaded) return;

    final pinned = List<String>.from(loaded.selectedCategoriesForTrend);
    if (pinned.contains(categoryId)) {
      pinned.remove(categoryId);
    } else if (pinned.length < 3) {
      pinned.add(categoryId);
    }
    _pinned
      ..clear()
      ..addAll(pinned);
    _recomputeTrends();
  }

  Future<void> refresh() => load();

  DateRange _resolveRange() {
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

    final now = DateTime.now();
    final range = _resolveRange();
    final expenses = await repository.getExpenses(range);
    final categories = await repository.getCategories();
    _lastRange = range;
    _lastExpenses = expenses;
    _lastCategories = categories;

    final monthlyTotals =
        calculator.computeMonthlyTotals(expenses, range);
    final breakdown = calculator.computeCategoryBreakdown(
      expenses,
      categories,
      foldThreshold: 0,
    );

    // Per-category month-over-month deltas — only meaningful for the
    // single-month "1M" view.
    final categoryMonthDeltas =
        _preset == AnalysisRangePreset.thisMonth
            ? calculator.computeCategoryMonthDeltas(
                all,
                categories,
                currentMonth: DateTime(now.year, now.month),
              )
            : const <CategoryMonthDelta>[];

    // Auto-pin the top 3 real categories (by share) on first analysis.
    if (_pinned.isEmpty && breakdown.isNotEmpty) {
      _pinned.addAll(
        breakdown
            .where((s) => s.amount > 0)
            .where((s) => s.categoryId != 'other')
            .take(3)
            .map((s) => s.categoryId),
      );
    }
    final effectivePinned = _pinned.length > 3
        ? List.of(_pinned.sublist(0, 3))
        : List<String>.of(_pinned);

    final trends = calculator.computeCategoryTrend(
      expenses,
      range,
      categories,
      categoryIds: effectivePinned.toSet(),
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
          dailyTotals: _preset != AnalysisRangePreset.thisMonth &&
                  range.monthCount == 1
              ? calculator.computeDailyTotals(expenses, range)
              : const [],
          categoryBreakdown: breakdown,
          categoryMonthDeltas: categoryMonthDeltas,
          selectedCategoriesForTrend: effectivePinned,
          categoryTrendData: trends,
          rangeComparison: comparison,
          insights: insights,
        ),
      );
  }

  /// Recompute just the pinned trend series (no repository access).
  void _recomputeTrends() {
    final loaded = state;
    if (loaded is! AnalysisLoaded ||
        _lastRange == null ||
        _lastExpenses == null ||
        _lastCategories == null) {
      return;
    }
    final trends = calculator.computeCategoryTrend(
      _lastExpenses!,
      _lastRange!,
      _lastCategories!,
      categoryIds: loaded.selectedCategoriesForTrend.toSet(),
    );
    emit(
      loaded.copyWith(
        selectedCategoriesForTrend:
            List<String>.from(loaded.selectedCategoriesForTrend),
        categoryTrendData: trends,
      ),
    );
  }
}