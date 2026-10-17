import 'package:flutter_test/flutter_test.dart';
import 'package:pebble/import/import_service.dart';
import 'package:pebble/data/expense_repository.dart';
import 'package:pebble/models/category.dart';
import 'package:pebble/models/date_range.dart';
import 'package:pebble/models/expense.dart';

/// In-memory repository fake — the import service only touches
/// getCategories / addCategory / addExpense.
class FakeExpenseRepository implements ExpenseRepository {
  final List<Expense> expenses = [];
  final List<ExpenseCategory> categories = [];

  @override
  Future<List<ExpenseCategory>> getCategories() async => List.of(categories);

  @override
  Future<void> addCategory(ExpenseCategory category) async =>
      categories.add(category);

  @override
  Future<void> addExpense(Expense expense) async => expenses.add(expense);

  @override
  Future<List<Expense>> getExpensesForMonth(int year, int month) async => [];
  @override
  Future<double> getTotalForMonth(int year, int month) async => 0;
  @override
  Future<List<Expense>> getExpenses(DateRange range) async => [];
  @override
  Future<void> updateExpense(Expense expense) async {}
  @override
  Future<void> deleteExpense(Expense expense) async {}
  @override
  Future<List<Expense>> getAllExpenses() async => List.of(expenses);
  @override
  Future<DateTime?> getLastExportDate() async => null;
  @override
  Future<void> setLastExportDate(DateTime date) async {}
  @override
  Future<DateTime?> getLastSnapshotDate() async => null;
  @override
  Future<void> setLastSnapshotDate(DateTime date) async {}
  @override
  Future<double?> getCategoryLimit(
    String categoryId,
    int year,
    int month,
  ) async => null;
  @override
  Future<Map<String, double>> getCategoryLimits(int year, int month) async =>
      {};
  @override
  Future<void> setCategoryLimit(
    String categoryId,
    int year,
    int month,
    double limit,
  ) async {}
  @override
  Future<void> unsetCategoryLimit(
    String categoryId,
    int year,
    int month,
  ) async {}
  @override
  Future<void> updateCategory(ExpenseCategory category) async {}
  @override
  Future<void> deleteCategory(String categoryId) async {}
  @override
  Future<void> initDefaultCategories(List<ExpenseCategory> defaults) async {}
}

void main() {
  group('ImportService CSV', () {
    test('imports rows and matches categories by name', () async {
      final repo = FakeExpenseRepository()
        ..categories.add(
          ExpenseCategory(
            id: 'food',
            label: 'Food',
            iconCodePoint: 0,
            colorValue: 0,
          ),
        );
      final service = ImportService(repo);

      const csv =
          'Date,Category,Amount,Note\n'
          '2025-04-10,Food,120.50,Lunch\n'
          '2025-04-12,Food,80,Snack\n';
      final result = await service.importCsv(csv);

      expect(result.importedExpenses, 2);
      expect(result.createdCategories, 0);
      expect(result.skipped, 0);
      expect(repo.expenses.length, 2);
      expect(repo.expenses.every((e) => e.categoryId == 'food'), isTrue);
      expect(repo.expenses.first.amount, 120.5);
      expect(repo.expenses.first.note, 'Lunch');
    });

    test('creates a new category when the name is unknown', () async {
      final repo = FakeExpenseRepository();
      final service = ImportService(repo);

      const csv =
          'Date,Category,Amount,Note\n'
          '2025-04-10,Travel,50,Train\n';
      final result = await service.importCsv(csv);

      expect(result.importedExpenses, 1);
      expect(result.createdCategories, 1);
      expect(repo.categories.length, 1);
      expect(repo.categories.first.label, 'Travel');
      expect(repo.expenses.first.categoryId, repo.categories.first.id);
    });

    test('skips malformed rows and the header', () async {
      final repo = FakeExpenseRepository();
      final service = ImportService(repo);

      const csv =
          'Date,Category,Amount,Note\n'
          'not-a-date,Food,10,x\n'
          '2025-04-10,Food,abc,x\n'
          '2025-04-10,Food,30,ok\n';
      final result = await service.importCsv(csv);

      expect(result.importedExpenses, 1);
      expect(result.skipped, 2);
    });
  });

  group('ImportService JSON', () {
    test('imports objects and matches categories', () async {
      final repo = FakeExpenseRepository()
        ..categories.add(
          ExpenseCategory(
            id: 'other',
            label: 'Other',
            iconCodePoint: 0,
            colorValue: 0,
          ),
        );
      final service = ImportService(repo);

      const json =
          '['
          '{"date":"2025-04-10","category":"Other","amount":99.00,"note":"misc"},'
          '{"date":"2025-04-11","category":"Other","amount":12.5,"note":null}'
          ']';
      final result = await service.importJson(json);

      expect(result.importedExpenses, 2);
      expect(result.createdCategories, 0);
      expect(repo.expenses.length, 2);
      expect(repo.expenses.first.amount, 99);
      expect(repo.expenses.first.note, 'misc');
      expect(repo.expenses.last.note, isNull);
    });

    test('creates missing category and skips bad entries', () async {
      final repo = FakeExpenseRepository();
      final service = ImportService(repo);

      const json =
          '['
          '{"date":"2025-04-10","category":"Subscriptions","amount":9.99},'
          '{"category":"X","amount":5},'
          '{"date":"bad","category":"X","amount":5}'
          ']';
      final result = await service.importJson(json);

      expect(result.importedExpenses, 1);
      expect(result.createdCategories, 1);
      expect(result.skipped, 2);
    });
  });
}
