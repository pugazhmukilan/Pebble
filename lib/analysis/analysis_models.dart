import 'package:equatable/equatable.dart';

/// Total spend for a single calendar month within an analysis range.
class MonthlyTotal extends Equatable {
  const MonthlyTotal({required this.month, required this.total});

  /// First day of the month.
  final DateTime month;
  final double total;

  @override
  List<Object?> get props => [month, total];
}

/// Total spend for a single day (used when the range is a single month,
/// which renders date-wise instead of month-wise).
class DailyTotal extends Equatable {
  const DailyTotal({required this.day, required this.total});

  final DateTime day;
  final double total;

  @override
  List<Object?> get props => [day, total];
}

/// Aggregate share of a category across the whole range.
class CategoryShare extends Equatable {
  const CategoryShare({
    required this.categoryId,
    required this.label,
    required this.amount,
    required this.percent,
    required this.colorValue,
  });

  final String categoryId;
  final String label;
  final double amount;

  /// Fraction of total spend, 0–100.
  final double percent;
  final int colorValue;

  @override
  List<Object?> get props => [categoryId, label, amount, percent, colorValue];
}

/// Per-category change between the current calendar month and the previous
/// one. Used by the "1M" analysis view to show how each category's spend
/// rose or fell month-over-month.
class CategoryMonthDelta extends Equatable {
  const CategoryMonthDelta({
    required this.categoryId,
    required this.label,
    required this.colorValue,
    required this.currentAmount,
    required this.previousAmount,
    required this.difference,
    this.percentChange,
  });

  final String categoryId;
  final String label;
  final int colorValue;

  /// Spend in the current month.
  final double currentAmount;

  /// Spend in the immediately preceding month (0 when the category had no
  /// spend last month).
  final double previousAmount;

  /// `currentAmount - previousAmount` (positive = spent more this month).
  final double difference;

  /// `difference / previousAmount`; null when [previousAmount] is zero so
  /// the UI never renders "∞%".
  final double? percentChange;

  @override
  List<Object?> get props => [
    categoryId,
    label,
    colorValue,
    currentAmount,
    previousAmount,
    difference,
    percentChange,
  ];
}

/// Per-month spend values for one category, aligned with
/// `DateRange.months`.
class CategoryTrend extends Equatable {
  const CategoryTrend({
    required this.categoryId,
    required this.label,
    required this.colorValue,
    required this.values,
  });

  final String categoryId;
  final String label;
  final int colorValue;

  /// One value per month in the range, oldest → newest.
  final List<double> values;

  @override
  List<Object?> get props => [categoryId, label, colorValue, values];
}

/// Result of comparing the selected range's spend against the equally-long
/// window that immediately precedes it.
class RangeComparison extends Equatable {
  const RangeComparison({
    required this.currentTotal,
    required this.previousTotal,
    required this.difference,
    required this.percentChange,
  });

  final double currentTotal;
  final double previousTotal;

  /// `currentTotal - previousTotal` (positive = spent more).
  final double difference;

  /// `difference / previousTotal`; null when [previousTotal] is zero so the
  /// UI never renders "∞%".
  final double? percentChange;

  @override
  List<Object?> get props =>
      [currentTotal, previousTotal, difference, percentChange];
}

/// Deterministic insight kinds — the calculator emits them, the UI renders
/// icons/labels from the kind.
enum InsightKind {
  spike,
  largestExpense,
  shareShift,
  flatStreak,
  highestMonth,
  newOrDormantCategory,
}

/// A single generated insight callout.
class Insight extends Equatable {
  const Insight({required this.kind, required this.title, required this.body});

  final InsightKind kind;
  final String title;
  final String body;

  @override
  List<Object?> get props => [kind, title, body];
}