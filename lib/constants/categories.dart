import 'package:flutter/material.dart';

import '../models/category.dart';
import 'category_colors.dart';

/// System-seeded categories. The 7 predefined mappings are permanent and
/// fixed to specific pool indices (§5.4) — they never go through the random
/// assignment path. "Other" is the system-reserved, non-pool category (§1.3).
final List<ExpenseCategory> defaultCategories = [
  ExpenseCategory(
    id: 'food',
    label: 'Food & Dining',
    iconCodePoint: Icons.restaurant_rounded.codePoint,
    colorValue: poolColorValue(10),
  ),
  ExpenseCategory(
    id: 'transport',
    label: 'Transport',
    iconCodePoint: Icons.directions_car_rounded.codePoint,
    colorValue: poolColorValue(0),
  ),
  ExpenseCategory(
    id: 'bills',
    label: 'Bills & Utilities',
    iconCodePoint: Icons.receipt_long_rounded.codePoint,
    colorValue: poolColorValue(14),
  ),
  ExpenseCategory(
    id: 'shopping',
    label: 'Shopping',
    iconCodePoint: Icons.shopping_bag_rounded.codePoint,
    colorValue: poolColorValue(5),
  ),
  ExpenseCategory(
    id: 'health',
    label: 'Health & Fitness',
    iconCodePoint: Icons.favorite_rounded.codePoint,
    colorValue: poolColorValue(7),
  ),
  ExpenseCategory(
    id: 'fun',
    label: 'Entertainment',
    iconCodePoint: Icons.sports_esports_rounded.codePoint,
    colorValue: poolColorValue(4),
  ),
  ExpenseCategory(
    id: 'home',
    label: 'Home',
    iconCodePoint: Icons.home_rounded.codePoint,
    colorValue: poolColorValue(15),
  ),
  ExpenseCategory(
    id: kOtherCategoryId,
    label: 'Other',
    iconCodePoint: Icons.more_horiz_rounded.codePoint,
    colorValue: kOtherColorLight.toARGB32(),
  ),
];
