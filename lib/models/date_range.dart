import 'package:equatable/equatable.dart';

/// Inclusive range of whole calendar months used to scope analysis queries.
///
/// [start] is the first day of the first month and [endInclusive] the last
/// instant of the last month, so a range always covers full months and
/// `contains` / `containsMonth` can be used directly as filters.
class DateRange extends Equatable {
  const DateRange({required this.start, required this.endInclusive});

  /// Covers the [monthCount] months ending at (and including) the given
  /// [now] month.
  factory DateRange.monthsFromNow({required int monthCount, DateTime? now}) {
    final today = now ?? DateTime.now();
    return DateRange(
      start: DateTime(today.year, today.month - (monthCount - 1)),
      endInclusive: _endOfMonth(today),
    );
  }

  /// Covers from [startMonth] through the current month.
  factory DateRange.untilNow({required DateTime startMonth, DateTime? now}) {
    final today = now ?? DateTime.now();
    return DateRange(
      start: DateTime(startMonth.year, startMonth.month),
      endInclusive: _endOfMonth(today),
    );
  }

  /// Covers exactly the single month [year]/[month].
  factory DateRange.exact({required int year, required int month}) {
    final monthStart = DateTime(year, month);
    return DateRange(start: monthStart, endInclusive: _endOfMonth(monthStart));
  }

  /// Covers every whole month from [startMonth] through [endMonth],
  /// inclusive. Used by the custom analysis range picker.
  factory DateRange.range({
    required DateTime startMonth,
    required DateTime endMonth,
  }) {
    final start = DateTime(startMonth.year, startMonth.month);
    final end = DateTime(endMonth.year, endMonth.month);
    return DateRange(start: start, endInclusive: _endOfMonth(end));
  }

  /// First day of the first month (00:00).
  final DateTime start;

  /// Last instant of the last month.
  final DateTime endInclusive;

  int get startYear => start.year;
  int get startMonth => start.month;
  int get endYear => endInclusive.year;
  int get endMonth => endInclusive.month;

  int get monthCount =>
      (endYear - startYear) * 12 + (endMonth - startMonth) + 1;

  /// First day of each covered month, oldest → newest.
  List<DateTime> get months => [
    for (var i = 0; i < monthCount; i++)
      DateTime(startYear, startMonth + i),
  ];

  bool contains(DateTime date) =>
      !date.isBefore(start) && !date.isAfter(endInclusive);

  bool containsMonth(int year, int month) {
    final at = DateTime(year, month);
    return !at.isBefore(DateTime(startYear, startMonth)) &&
        !at.isAfter(DateTime(endYear, endMonth));
  }

  /// The [monthCount] months immediately preceding [start] (used as the
  /// comparison window).
  DateRange previousWindow() {
    final prevEnd = DateTime(startYear, startMonth - 1);
    final prevStart = DateTime(prevEnd.year, prevEnd.month - (monthCount - 1));
    return DateRange(start: prevStart, endInclusive: _endOfMonth(prevEnd));
  }

  static DateTime _endOfMonth(DateTime month) =>
      DateTime(month.year, month.month + 1)
          .subtract(const Duration(microseconds: 1));

  @override
  List<Object?> get props => [start, endInclusive];
}