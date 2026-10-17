import 'package:equatable/equatable.dart';

import '../../models/category.dart';
import '../../models/expense.dart';

/// Direction of month navigation for slide animations.
enum MonthDirection { none, forward, backward }

/// Immutable expense states — sealed class hierarchy.
/// Uses Equatable for value comparison so BlocBuilder doesn't rebuild
/// on identical states (§14).
sealed class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded.
final class ExpenseInitial extends ExpenseState {
  const ExpenseInitial();
}

/// Data is being fetched.
final class ExpenseLoading extends ExpenseState {
  const ExpenseLoading();
}

/// Data loaded successfully — carries the selected month's expenses,
/// pre-computed total, and category breakdown map.
final class ExpenseLoaded extends ExpenseState {
  const ExpenseLoaded({
    required this.expenses,
    required this.total,
    required this.categoryBreakdown,
    required this.categories,
    required this.selectedYear,
    required this.selectedMonth,
    required this.isCurrentMonth,
    this.categoryLimits = const {},
    this.previousMonthTotal = 0,
    this.lastExportDate,
    this.monthDirection = MonthDirection.none,
  });

  final List<Expense> expenses;
  final double total;
  final Map<String, double> categoryBreakdown;
  final List<ExpenseCategory> categories;
  final int selectedYear;
  final int selectedMonth;
  final bool isCurrentMonth;
  final Map<String, double> categoryLimits;

  /// Total spent in the month before the selected month, used as the
  /// baseline for the compact delta ticker next to the total.
  final double previousMonthTotal;
  final DateTime? lastExportDate;
  final MonthDirection monthDirection;

  @override
  List<Object?> get props => [
    expenses,
    total,
    categoryBreakdown,
    categories,
    selectedYear,
    selectedMonth,
    isCurrentMonth,
    categoryLimits,
    previousMonthTotal,
    lastExportDate,
    monthDirection,
  ];
}

/// Something went wrong.
final class ExpenseError extends ExpenseState {
  const ExpenseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
