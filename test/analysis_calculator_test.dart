import 'package:flutter_test/flutter_test.dart';
import 'package:pebble/analysis/analysis_calculator.dart';
import 'package:pebble/analysis/analysis_models.dart';
import 'package:pebble/analysis/analysis_thresholds.dart';
import 'package:pebble/models/category.dart';
import 'package:pebble/models/date_range.dart';
import 'package:pebble/models/expense.dart';

void main() {
  const calculator = AnalysisCalculator();

  Expense expense({
    required double amount,
    required String categoryId,
    required int year,
    required int month,
    int day = 5,
  }) {
    return Expense(
      amount: amount,
      categoryId: categoryId,
      date: DateTime(year, month, day),
      createdAt: DateTime(year, month, day),
    );
  }

  ExpenseCategory category(String id, {String label = '', int color = 0xFF000000}) {
    return ExpenseCategory(
      id: id,
      label: label.isEmpty ? id : label,
      iconCodePoint: 0,
      colorValue: color,
    );
  }

  group('computeMonthlyTotals', () {
    test('zero-fills empty months inside the range', () {
      final range = DateRange.untilNow(
        startMonth: DateTime(2025, 1),
        now: DateTime(2025, 4, 15),
      );
      final totals = calculator.computeMonthlyTotals(
        [
          expense(amount: 100, categoryId: 'food', year: 2025, month: 1),
          expense(amount: 50, categoryId: 'food', year: 2025, month: 4),
        ],
        range,
      );
      expect(totals.length, 4);
      expect(totals[0].total, 100);
      expect(totals[1].total, 0);
      expect(totals[2].total, 0);
      expect(totals[3].total, 50);
      expect(totals[0].month, DateTime(2025, 1));
    });
  });

  group('computeDailyTotals', () {
    test('returns one total per day, zero-filled', () {
      final range = DateRange.exact(year: 2025, month: 2);
      final totals = calculator.computeDailyTotals(
        [
          expense(amount: 10, categoryId: 'a', year: 2025, month: 2, day: 1),
          expense(amount: 20, categoryId: 'a', year: 2025, month: 2, day: 1),
          expense(amount: 5, categoryId: 'b', year: 2025, month: 2, day: 2),
        ],
        range,
      );
      expect(totals.length, 28);
      expect(totals[0].total, 30);
      expect(totals[1].total, 5);
      expect(totals[2].total, 0);
    });
  });

  group('computeCategoryBreakdown', () {
    test('sorts by amount descending', () {
      final slices = calculator.computeCategoryBreakdown(
        [
          expense(amount: 10, categoryId: 'a', year: 2025, month: 1),
          expense(amount: 60, categoryId: 'b', year: 2025, month: 1),
          expense(amount: 30, categoryId: 'c', year: 2025, month: 1),
        ],
        [category('a'), category('b'), category('c')],
      );
      expect(slices.map((s) => s.categoryId), ['b', 'c', 'a']);
    });

    test('folds categories under 3% into an Other slice', () {
      final slices = calculator.computeCategoryBreakdown(
        [
          expense(amount: 970, categoryId: 'a', year: 2025, month: 1),
          expense(amount: 10, categoryId: 'tiny1', year: 2025, month: 1),
          expense(amount: 20, categoryId: 'tiny2', year: 2025, month: 1),
        ],
        [category('a'), category('tiny1'), category('tiny2')],
      );
      final ids = slices.map((s) => s.categoryId).toList();
      expect(ids, containsAll(['a', 'other']));
      final other = slices.firstWhere((s) => s.categoryId == 'other');
      expect(other.amount, closeTo(30, 0.001));
    });

    test('returns empty for no expenses', () {
      final result = calculator.computeCategoryBreakdown([], [category('food')]);
      expect(result, isEmpty);
    });

    test('foldThreshold: 0 keeps every category (no Other fold)', () {
      final expenses = [
        expense(amount: 100, categoryId: 'food', year: 2025, month: 4),
        expense(amount: 1, categoryId: 'travel', year: 2025, month: 4),
      ];
      final result = calculator.computeCategoryBreakdown(
        expenses,
        [category('food'), category('travel')],
        foldThreshold: 0,
      );
      expect(result.length, 2);
      expect(result.any((s) => s.categoryId == 'other'), isFalse);
    });
  });

  group('computeCategoryTrend', () {
    test('aligns values to range months, zero-filled', () {
      final range = DateRange.untilNow(
        startMonth: DateTime(2025, 1),
        now: DateTime(2025, 3, 15),
      );
      final trends = calculator.computeCategoryTrend(
        [
          expense(amount: 10, categoryId: 'a', year: 2025, month: 1),
          expense(amount: 20, categoryId: 'a', year: 2025, month: 3),
          expense(amount: 999, categoryId: 'b', year: 2025, month: 2),
        ],
        range,
        [category('a'), category('b')],
        categoryIds: {'a'},
      );
      expect(trends.length, 1);
      expect(trends.first.values, [10, 0, 20]);
    });
  });

  group('compareToPreviousRange', () {
    test('percent is null when previous total is zero (no ∞%)', () {
      final comparison = calculator.compareToPreviousRange(500, 0);
      expect(comparison.difference, 500);
      expect(comparison.percentChange, isNull);
    });

    test('computes signed difference and percent', () {
      final comparison = calculator.compareToPreviousRange(400, 500);
      expect(comparison.difference, -100);
      expect(comparison.percentChange, closeTo(-0.2, 0.0001));
    });
  });

  group('generateInsights', () {
    test('returns empty when fewer than two months of data', () {
      final range = DateRange.exact(year: 2025, month: 1);
      final totals = calculator.computeMonthlyTotals(
        [expense(amount: 100, categoryId: 'a', year: 2025, month: 1)],
        range,
      );
      final insights = calculator.generateInsights(
        expenses: [expense(amount: 100, categoryId: 'a', year: 2025, month: 1)],
        monthlyTotals: totals,
        categories: [category('a')],
      );
      expect(insights, isEmpty);
    });

    test('never emits a spike when no month is 30% above average', () {
      final expenses = [
        expense(amount: 100, categoryId: 'a', year: 2025, month: 1),
        expense(amount: 110, categoryId: 'a', year: 2025, month: 2),
      ];
      final range = DateRange.untilNow(
        startMonth: DateTime(2025, 1),
        now: DateTime(2025, 2, 15),
      );
      final totals = calculator.computeMonthlyTotals(expenses, range);
      final insights = calculator.generateInsights(
        expenses: expenses,
        monthlyTotals: totals,
        categories: [category('a')],
      );
      expect(
        insights.where((i) => i.kind == InsightKind.spike),
        isEmpty,
      );
    });

    test('emits spike, highest month and largest expense from clean data', () {
      final expenses = [
        expense(amount: 300, categoryId: 'a', year: 2025, month: 1),
        expense(amount: 300, categoryId: 'a', year: 2025, month: 2),
        expense(amount: 900, categoryId: 'b', year: 2025, month: 3),
        expense(amount: 800, categoryId: 'b', year: 2025, month: 3),
      ];
      final range = DateRange.untilNow(
        startMonth: DateTime(2025, 1),
        now: DateTime(2025, 3, 15),
      );
      final totals = calculator.computeMonthlyTotals(expenses, range);
      final insights = calculator.generateInsights(
        expenses: expenses,
        monthlyTotals: totals,
        categories: [category('a'), category('b')],
      );
      final kinds = insights.map((i) => i.kind).toSet();
      expect(kinds, contains(InsightKind.spike));
      expect(kinds, contains(InsightKind.highestMonth));
      expect(kinds, contains(InsightKind.largestExpense));
    });

    test('emits a flat streak for three within-band months', () {
      final expenses = [
        expense(amount: 100, categoryId: 'a', year: 2025, month: 1),
        expense(amount: 103, categoryId: 'a', year: 2025, month: 2),
        expense(amount: 98, categoryId: 'a', year: 2025, month: 3),
      ];
      final range = DateRange.untilNow(
        startMonth: DateTime(2025, 1),
        now: DateTime(2025, 3, 15),
      );
      final totals = calculator.computeMonthlyTotals(expenses, range);
      final insights = calculator.generateInsights(
        expenses: expenses,
        monthlyTotals: totals,
        categories: [category('a')],
      );
      expect(
        insights.where((i) => i.kind == InsightKind.flatStreak),
        isNotEmpty,
      );
    });

    test('respects the spike threshold constant', () {
      expect(kInsightSpikeThreshold, 0.30);
      expect(kInsightLargestMin, 500);
      expect(kInsightFlatBand, 0.05);
      expect(kInsightShareShiftPp, 10);
    });
  });

  group('DateRange', () {
    test('previousWindow returns the equally-long preceding window', () {
      final range = DateRange.untilNow(
        startMonth: DateTime(2025, 3),
        now: DateTime(2025, 5, 10),
      );
      final previous = range.previousWindow();
      expect(previous.monthCount, range.monthCount);
      expect(
        previous.endInclusive.millisecondsSinceEpoch,
        DateTime(2025, 3).subtract(const Duration(microseconds: 1)).millisecondsSinceEpoch,
      );
      expect(previous.start, DateTime(2024, 12));
    });

    test('containsMonth respects boundaries', () {
      final range = DateRange.untilNow(
        startMonth: DateTime(2025, 3),
        now: DateTime(2025, 5, 10),
      );
      expect(range.containsMonth(2025, 3), isTrue);
      expect(range.containsMonth(2025, 5), isTrue);
      expect(range.containsMonth(2025, 2), isFalse);
      expect(range.containsMonth(2025, 6), isFalse);
    });
  });

  group('computeCategoryMonthDeltas', () {
    test('computes rise/fall vs the previous calendar month', () {
      final expenses = [
        expense(amount: 100, categoryId: 'food', year: 2025, month: 4),
        expense(amount: 150, categoryId: 'food', year: 2025, month: 5),
        expense(amount: 80, categoryId: 'travel', year: 2025, month: 4),
        expense(amount: 40, categoryId: 'travel', year: 2025, month: 5),
      ];
      final categories = [
        category('food', label: 'Food'),
        category('travel', label: 'Travel'),
      ];
      final deltas = calculator.computeCategoryMonthDeltas(
        expenses,
        categories,
        currentMonth: DateTime(2025, 5),
      );
      final byId = {for (final d in deltas) d.categoryId: d};
      expect(byId['food']!.currentAmount, 150);
      expect(byId['food']!.previousAmount, 100);
      expect(byId['food']!.difference, 50);
      expect(byId['food']!.percentChange, 50);
      expect(byId['travel']!.difference, -40);
      expect(byId['travel']!.percentChange, -50);
    });

    test('percentChange is null when a category is new this month', () {
      final expenses = [
        expense(amount: 200, categoryId: 'food', year: 2025, month: 5),
      ];
      final deltas = calculator.computeCategoryMonthDeltas(
        expenses,
        [category('food', label: 'Food')],
        currentMonth: DateTime(2025, 5),
      );
      expect(deltas.single.previousAmount, 0);
      expect(deltas.single.difference, 200);
      expect(deltas.single.percentChange, isNull);
    });
  });
}