import 'package:equatable/equatable.dart';

import '../../analysis/analysis_models.dart';
import '../../models/category.dart';
import '../../models/date_range.dart';

/// Presets for the analysis range selector.
enum AnalysisRangePreset {
  thisMonth('1M', 1),
  threeMonths('3M', 3),
  sixMonths('6M', 6),
  oneYear('1Y', 12);

  const AnalysisRangePreset(this.label, this.defaultMonths);
  final String label;
  final int defaultMonths;
}

/// Immutable analysis states — sealed hierarchy, Equatable value equality.
sealed class AnalysisState extends Equatable {
  const AnalysisState();

  @override
  List<Object?> get props => [];
}

/// Nothing loaded yet.
final class AnalysisInitial extends AnalysisState {
  const AnalysisInitial();
}

/// Data is being fetched / recomputed.
final class AnalysisLoading extends AnalysisState {
  const AnalysisLoading();
}

/// Not enough history — fewer than two full months of data.
final class AnalysisEmpty extends AnalysisState {
  const AnalysisEmpty();
}

/// Analysis computed and ready to render.
final class AnalysisLoaded extends AnalysisState {
  const AnalysisLoaded({
    required this.preset,
    required this.range,
    required this.categories,
    required this.monthlyTotals,
    required this.dailyTotals,
    required this.categoryBreakdown,
    required this.categoryMonthDeltas,
    required this.selectedCategoriesForTrend,
    required this.categoryTrendData,
    required this.rangeComparison,
    required this.insights,
  });

  final AnalysisRangePreset preset;
  final DateRange range;
  final List<ExpenseCategory> categories;
  final List<MonthlyTotal> monthlyTotals;

  /// Per-day spend when the range is a single calendar month (date-wise
  /// trend); otherwise empty.
  final List<DailyTotal> dailyTotals;
  final List<CategoryShare> categoryBreakdown;

  /// Per-category month-over-month change for the "1M" view: how much each
  /// category's spend rose or fell versus the previous calendar month.
  final List<CategoryMonthDelta> categoryMonthDeltas;

  /// Category ids currently pinned for the per-category trend (max 3), in
  /// display order.
  final List<String> selectedCategoriesForTrend;
  final List<CategoryTrend> categoryTrendData;
  final RangeComparison rangeComparison;
  final List<Insight> insights;

  AnalysisLoaded copyWith({
    List<String>? selectedCategoriesForTrend,
    List<CategoryTrend>? categoryTrendData,
  }) {
    return AnalysisLoaded(
      preset: preset,
      range: range,
      categories: categories,
      monthlyTotals: monthlyTotals,
      dailyTotals: dailyTotals,
      categoryBreakdown: categoryBreakdown,
      categoryMonthDeltas: categoryMonthDeltas,
      selectedCategoriesForTrend:
          selectedCategoriesForTrend ?? this.selectedCategoriesForTrend,
      categoryTrendData: categoryTrendData ?? this.categoryTrendData,
      rangeComparison: rangeComparison,
      insights: insights,
    );
  }

  @override
  List<Object?> get props => [
    preset,
    range,
    categories,
    monthlyTotals,
    dailyTotals,
    categoryBreakdown,
    categoryMonthDeltas,
    selectedCategoriesForTrend,
    categoryTrendData,
    rangeComparison,
    insights,
  ];
}

/// Something went wrong.
final class AnalysisError extends AnalysisState {
  const AnalysisError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}