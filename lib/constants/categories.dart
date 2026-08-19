import 'package:flutter/material.dart';
import '../models/category.dart';

final List<ExpenseCategory> defaultCategories = [
  ExpenseCategory(
    id: 'food',
    label: 'Food & Dining',
    iconCodePoint: Icons.restaurant_rounded.codePoint,
    colorValue: 0xFFFFB74D,
  ),
  ExpenseCategory(
    id: 'transport',
    label: 'Transport',
    iconCodePoint: Icons.directions_car_rounded.codePoint,
    colorValue: 0xFF64B5F6,
  ),
  ExpenseCategory(
    id: 'bills',
    label: 'Bills & Utilities',
    iconCodePoint: Icons.receipt_long_rounded.codePoint,
    colorValue: 0xFF81C784,
  ),
  ExpenseCategory(
    id: 'shopping',
    label: 'Shopping',
    iconCodePoint: Icons.shopping_bag_rounded.codePoint,
    colorValue: 0xFFBA68C8,
  ),
  ExpenseCategory(
    id: 'health',
    label: 'Health & Fitness',
    iconCodePoint: Icons.favorite_rounded.codePoint,
    colorValue: 0xFFE57373,
  ),
  ExpenseCategory(
    id: 'fun',
    label: 'Entertainment',
    iconCodePoint: Icons.sports_esports_rounded.codePoint,
    colorValue: 0xFFFFD54F,
  ),
  ExpenseCategory(
    id: 'home',
    label: 'Home',
    iconCodePoint: Icons.home_rounded.codePoint,
    colorValue: 0xFF4DB6AC,
  ),
  ExpenseCategory(
    id: 'other',
    label: 'Other',
    iconCodePoint: Icons.more_horiz_rounded.codePoint,
    colorValue: 0xFF90A4AE,
  ),
];
