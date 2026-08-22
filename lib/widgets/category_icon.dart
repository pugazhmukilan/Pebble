import 'package:flutter/material.dart';

import '../constants/category_icons.dart';
import '../models/category.dart';

/// Renders a category's icon — an emoji if set, otherwise the Material icon.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 24,
    this.color,
  });

  final ExpenseCategory category;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final emoji = category.emoji;
    if (emoji != null && emoji.isNotEmpty) {
      return Center(
        child: Text(
          emoji,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: size * 0.75, height: 1.0),
        ),
      );
    }
    return Icon(
      resolveCategoryIcon(category.iconCodePoint),
      size: size,
      color: color,
    );
  }
}
