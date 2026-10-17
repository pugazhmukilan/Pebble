import 'package:flutter_test/flutter_test.dart';
import 'package:pebble/analysis/category_limit_resolver.dart';
import 'package:pebble/models/category_limit_change.dart';

void main() {
  CategoryLimitChange change({
    required int year,
    required int month,
    required double? limit,
  }) {
    return CategoryLimitChange(
      categoryId: 'food',
      effectiveYear: year,
      effectiveMonth: month,
      limit: limit,
    );
  }

  test('returns no limit before the first change', () {
    final result = CategoryLimitResolver.resolve(
      [change(year: 2026, month: 10, limit: 5000)],
      'food',
      2026,
      9,
    );

    expect(result, isNull);
  });

  test('inherits a limit into later months', () {
    final changes = [change(year: 2026, month: 10, limit: 5000)];

    expect(CategoryLimitResolver.resolve(changes, 'food', 2026, 10), 5000);
    expect(CategoryLimitResolver.resolve(changes, 'food', 2026, 11), 5000);
  });

  test('a later change does not alter an earlier month', () {
    final changes = [
      change(year: 2026, month: 10, limit: 5000),
      change(year: 2026, month: 11, limit: 6000),
    ];

    expect(CategoryLimitResolver.resolve(changes, 'food', 2026, 10), 5000);
    expect(CategoryLimitResolver.resolve(changes, 'food', 2026, 11), 6000);
  });

  test('an unset change removes the limit going forward', () {
    final changes = [
      change(year: 2026, month: 10, limit: 5000),
      change(year: 2026, month: 11, limit: null),
    ];

    expect(CategoryLimitResolver.resolve(changes, 'food', 2026, 10), 5000);
    expect(CategoryLimitResolver.resolve(changes, 'food', 2026, 11), isNull);
  });

  test('same-month changes use the latest stored change', () {
    final changes = [
      change(year: 2026, month: 10, limit: 5000),
      change(year: 2026, month: 10, limit: 7000),
    ];

    expect(CategoryLimitResolver.resolve(changes, 'food', 2026, 10), 7000);
  });

  test('resolveAll excludes unset categories', () {
    final changes = [
      change(year: 2026, month: 10, limit: 5000),
      change(year: 2026, month: 11, limit: null),
    ];

    expect(CategoryLimitResolver.resolveAll(changes, 2026, 10), {'food': 5000});
    expect(CategoryLimitResolver.resolveAll(changes, 2026, 11), isEmpty);
  });
}
