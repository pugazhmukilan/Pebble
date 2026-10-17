import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category.dart';
import '../models/category_limit_change.dart';
import '../models/date_range.dart';
import '../models/expense.dart';
import '../analysis/category_limit_resolver.dart';

/// Abstract repository interface — Cubit depends on this, not the concrete
/// Hive implementation (Dependency Inversion, §14).
abstract class ExpenseRepository {
  Future<List<Expense>> getExpensesForMonth(int year, int month);
  Future<double> getTotalForMonth(int year, int month);
  Future<List<Expense>> getExpenses(DateRange range);
  Future<void> addExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(Expense expense);
  Future<List<Expense>> getAllExpenses();
  Future<DateTime?> getLastExportDate();
  Future<void> setLastExportDate(DateTime date);
  Future<DateTime?> getLastSnapshotDate();
  Future<void> setLastSnapshotDate(DateTime date);
  Future<double?> getCategoryLimit(String categoryId, int year, int month);
  Future<Map<String, double>> getCategoryLimits(int year, int month);
  Future<void> setCategoryLimit(
    String categoryId,
    int year,
    int month,
    double limit,
  );
  Future<void> unsetCategoryLimit(String categoryId, int year, int month);
  Future<List<ExpenseCategory>> getCategories();
  Future<void> addCategory(ExpenseCategory category);
  Future<void> updateCategory(ExpenseCategory category);
  Future<void> deleteCategory(String categoryId);
  Future<void> initDefaultCategories(List<ExpenseCategory> defaults);
}

/// Hive-backed implementation of [ExpenseRepository].
class HiveExpenseRepository implements ExpenseRepository {
  HiveExpenseRepository(this._expenseBox, this._categoryBox, this._limitBox);

  final Box<Expense> _expenseBox;
  final Box<ExpenseCategory> _categoryBox;
  final Box<CategoryLimitChange> _limitBox;
  static const _lastExportKey = 'last_export_date';
  static const _lastSnapshotKey = 'last_auto_snapshot_date';

  @override
  Future<List<Expense>> getExpensesForMonth(int year, int month) async {
    return _expenseBox.values
        .where((e) => e.date.year == year && e.date.month == month)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<double> getTotalForMonth(int year, int month) async {
    var total = 0.0;
    for (final expense in _expenseBox.values.where(
      (e) => e.date.year == year && e.date.month == month,
    )) {
      total += expense.amount;
    }
    return total;
  }

  @override
  Future<List<Expense>> getExpenses(DateRange range) async {
    return _expenseBox.values.where((e) => range.contains(e.date)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<void> addExpense(Expense expense) async {
    await _expenseBox.add(expense);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await expense.save();
  }

  @override
  Future<void> deleteExpense(Expense expense) async {
    await expense.delete();
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    return _expenseBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<DateTime?> getLastExportDate() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastExportKey);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  @override
  Future<void> setLastExportDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastExportKey, date.millisecondsSinceEpoch);
  }

  @override
  Future<DateTime?> getLastSnapshotDate() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastSnapshotKey);
    return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
  }

  @override
  Future<void> setLastSnapshotDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSnapshotKey, date.millisecondsSinceEpoch);
  }

  @override
  Future<double?> getCategoryLimit(
    String categoryId,
    int year,
    int month,
  ) async {
    return CategoryLimitResolver.resolve(
      _limitBox.values,
      categoryId,
      year,
      month,
    );
  }

  @override
  Future<Map<String, double>> getCategoryLimits(int year, int month) async {
    return CategoryLimitResolver.resolveAll(_limitBox.values, year, month);
  }

  @override
  Future<void> setCategoryLimit(
    String categoryId,
    int year,
    int month,
    double limit,
  ) async {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'must be greater than zero');
    }
    final key = _limitKey(categoryId, year, month);
    await _limitBox.put(
      key,
      CategoryLimitChange(
        categoryId: categoryId,
        effectiveYear: year,
        effectiveMonth: month,
        limit: limit,
      ),
    );
    await _limitBox.flush();
    final saved = _limitBox.get(key);
    if (saved?.limit != limit) {
      throw StateError('Category limit could not be verified after saving');
    }
  }

  @override
  Future<void> unsetCategoryLimit(
    String categoryId,
    int year,
    int month,
  ) async {
    final key = _limitKey(categoryId, year, month);
    await _limitBox.put(
      key,
      CategoryLimitChange(
        categoryId: categoryId,
        effectiveYear: year,
        effectiveMonth: month,
        limit: null,
      ),
    );
    await _limitBox.flush();
    final saved = _limitBox.get(key);
    if (saved == null || saved.limit != null) {
      throw StateError('Category limit removal could not be verified');
    }
  }

  @override
  Future<List<ExpenseCategory>> getCategories() async {
    return _categoryBox.values.toList();
  }

  @override
  Future<void> addCategory(ExpenseCategory category) async {
    await _categoryBox.put(category.id, category);
  }

  @override
  Future<void> updateCategory(ExpenseCategory category) async {
    await _categoryBox.put(category.id, category);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    // Reassign expenses of the deleted category to "other" (or the first
    // remaining category) so no entry is left orphaned.
    String? fallback;
    final ids = _categoryBox.keys.cast<String>().toList();
    if (ids.contains('other') && categoryId != 'other') {
      fallback = 'other';
    } else {
      fallback = ids.where((id) => id != categoryId).firstOrNull;
    }
    if (fallback != null && fallback != categoryId) {
      for (final expense in _expenseBox.values.where(
        (e) => e.categoryId == categoryId,
      )) {
        expense.categoryId = fallback;
        await expense.save();
      }
    }
    await _categoryBox.delete(categoryId);
    final limitKeys = _limitBox.keys.where((key) {
      final change = _limitBox.get(key);
      return change?.categoryId == categoryId;
    }).toList();
    await _limitBox.deleteAll(limitKeys);
  }

  static String _limitKey(String categoryId, int year, int month) =>
      '$categoryId|$year|$month';

  @override
  Future<void> initDefaultCategories(List<ExpenseCategory> defaults) async {
    if (_categoryBox.isEmpty) {
      for (final cat in defaults) {
        await _categoryBox.put(cat.id, cat);
      }
      return;
    }
    // Income was a temporary experiment — purge it (and reassign any of its
    // entries) for installs that may have picked it up.
    if (_categoryBox.containsKey('income')) {
      await deleteCategory('income');
    }
  }
}
