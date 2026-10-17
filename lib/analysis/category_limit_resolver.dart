import '../models/category_limit_change.dart';

class CategoryLimitResolver {
  const CategoryLimitResolver._();

  static double? resolve(
    Iterable<CategoryLimitChange> changes,
    String categoryId,
    int year,
    int month,
  ) {
    CategoryLimitChange? latest;
    for (final change in changes.where(
      (change) =>
          change.categoryId == categoryId &&
          _isOnOrBefore(
            change.effectiveYear,
            change.effectiveMonth,
            year,
            month,
          ),
    )) {
      if (latest == null || _isOnOrBeforeChange(latest, change)) {
        latest = change;
      }
    }
    return latest?.limit;
  }

  static Map<String, double> resolveAll(
    Iterable<CategoryLimitChange> changes,
    int year,
    int month,
  ) {
    final latestByCategory = <String, CategoryLimitChange>{};
    for (final change in changes.where(
      (change) => _isOnOrBefore(
        change.effectiveYear,
        change.effectiveMonth,
        year,
        month,
      ),
    )) {
      final previous = latestByCategory[change.categoryId];
      if (previous == null || _isOnOrBeforeChange(previous, change)) {
        latestByCategory[change.categoryId] = change;
      }
    }
    return {
      for (final entry in latestByCategory.entries)
        if (entry.value.limit != null) entry.key: entry.value.limit!,
    };
  }

  static bool _isOnOrBeforeChange(
    CategoryLimitChange first,
    CategoryLimitChange second,
  ) {
    return _isOnOrBefore(
      first.effectiveYear,
      first.effectiveMonth,
      second.effectiveYear,
      second.effectiveMonth,
    );
  }

  static bool _isOnOrBefore(
    int year,
    int month,
    int targetYear,
    int targetMonth,
  ) {
    return year < targetYear || (year == targetYear && month <= targetMonth);
  }
}
