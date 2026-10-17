import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/category.dart';
import '../../data/expense_repository.dart';
import '../../models/expense.dart';
import 'expense_state.dart';

/// Manages the selected month's expense data.
///
/// Computes total and category breakdown once per state change inside
/// the cubit — widgets never recompute these in build() (§14 performance).
class ExpenseCubit extends Cubit<ExpenseState> {
  ExpenseCubit(this.repository) : super(const ExpenseInitial());

  final ExpenseRepository repository;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  MonthDirection _lastDirection = MonthDirection.none;

  /// Load expenses for the current selected month.
  Future<void> loadExpenses() async {
    emit(const ExpenseLoading());
    try {
      final expenses = await repository.getExpensesForMonth(
        _selectedYear,
        _selectedMonth,
      );
      final categories = await repository.getCategories();
      final categoryLimits = await repository.getCategoryLimits(
        _selectedYear,
        _selectedMonth,
      );
      final lastExport = await repository.getLastSnapshotDate();

      // Month-over-month ticker: total of the month before the selection.
      int prevYear = _selectedYear, prevMonth = _selectedMonth - 1;
      if (prevMonth == 0) {
        prevYear--;
        prevMonth = 12;
      }
      final previousMonthTotal = await repository.getTotalForMonth(
        prevYear,
        prevMonth,
      );

      _emitLoaded(
        expenses,
        categories,
        categoryLimits,
        lastExport,
        previousMonthTotal,
      );
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  /// Navigate to next month.
  Future<void> nextMonth() async {
    final now = DateTime.now();
    if (_selectedYear == now.year && _selectedMonth == now.month) {
      return; // Can't go into the future
    }

    _lastDirection = MonthDirection.forward;
    if (_selectedMonth == 12) {
      _selectedMonth = 1;
      _selectedYear++;
    } else {
      _selectedMonth++;
    }
    await loadExpenses();
  }

  /// Navigate to previous month.
  Future<void> previousMonth() async {
    _lastDirection = MonthDirection.backward;
    if (_selectedMonth == 1) {
      _selectedMonth = 12;
      _selectedYear--;
    } else {
      _selectedMonth--;
    }
    await loadExpenses();
  }

  /// Jump to a specific month/year (from month picker).
  Future<void> changeMonth(int year, int month) async {
    _lastDirection =
        year > _selectedYear ||
            (year == _selectedYear && month > _selectedMonth)
        ? MonthDirection.forward
        : MonthDirection.backward;
    _selectedYear = year;
    _selectedMonth = month;
    await loadExpenses();
  }

  /// Add a new expense and reload the month.
  Future<void> addExpense({
    required double amount,
    required String categoryId,
    required DateTime date,
    String? note,
  }) async {
    final expense = Expense(
      amount: amount,
      categoryId: categoryId,
      date: date,
      createdAt: DateTime.now(),
      note: note?.trim().isEmpty == true ? null : note?.trim(),
    );
    await repository.addExpense(expense);
    await loadExpenses();
  }

  /// Update an existing expense and reload.
  Future<void> updateExpense(
    Expense expense, {
    required double amount,
    required String categoryId,
    required DateTime date,
    String? note,
  }) async {
    expense.amount = amount;
    expense.categoryId = categoryId;
    expense.date = date;
    expense.note = note?.trim().isEmpty == true ? null : note?.trim();
    await repository.updateExpense(expense);
    await loadExpenses();
  }

  /// Delete an expense and reload.
  Future<void> deleteExpense(Expense expense) async {
    await repository.deleteExpense(expense);
    await loadExpenses();
  }

  /// Update a category's details and reload.
  Future<void> updateCategory(ExpenseCategory category) async {
    await repository.updateCategory(category);
    await loadExpenses();
  }

  /// Delete a category and reload. Its expenses are reassigned by the
  /// repository (to "other" or the first remaining category).
  Future<void> deleteCategory(String categoryId) async {
    await repository.deleteCategory(categoryId);
    await loadExpenses();
  }

  Future<void> setCategoryLimit(String categoryId, double limit) async {
    final now = DateTime.now();
    await repository.setCategoryLimit(categoryId, now.year, now.month, limit);
    await loadExpenses();
  }

  Future<void> unsetCategoryLimit(String categoryId) async {
    final now = DateTime.now();
    await repository.unsetCategoryLimit(categoryId, now.year, now.month);
    await loadExpenses();
  }

  /// Refresh the last export date indicator without reloading expenses.
  Future<void> refreshExportDate() async {
    if (state is ExpenseLoaded) {
      final current = state as ExpenseLoaded;
      final lastExport = await repository.getLastSnapshotDate();
      emit(
        ExpenseLoaded(
          expenses: current.expenses,
          total: current.total,
          categoryBreakdown: current.categoryBreakdown,
          categories: current.categories,
          selectedYear: current.selectedYear,
          selectedMonth: current.selectedMonth,
          isCurrentMonth: current.isCurrentMonth,
          categoryLimits: current.categoryLimits,
          previousMonthTotal: current.previousMonthTotal,
          lastExportDate: lastExport,
        ),
      );
    }
  }

  /// Compute totals and emit loaded state.
  void _emitLoaded(
    List<Expense> expenses,
    List<ExpenseCategory> categories,
    Map<String, double> categoryLimits,
    DateTime? lastExport,
    double previousMonthTotal,
  ) {
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedYear == now.year && _selectedMonth == now.month;

    double total = 0;
    final breakdown = <String, double>{};
    for (final expense in expenses) {
      total += expense.amount;
      breakdown[expense.categoryId] =
          (breakdown[expense.categoryId] ?? 0) + expense.amount;
    }

    final direction = _lastDirection;
    _lastDirection = MonthDirection.none;

    emit(
      ExpenseLoaded(
        expenses: expenses,
        total: total,
        categoryBreakdown: breakdown,
        categories: categories,
        selectedYear: _selectedYear,
        selectedMonth: _selectedMonth,
        isCurrentMonth: isCurrentMonth,
        categoryLimits: categoryLimits,
        previousMonthTotal: previousMonthTotal,
        lastExportDate: lastExport,
        monthDirection: direction,
      ),
    );
  }
}
