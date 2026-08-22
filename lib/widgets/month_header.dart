import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Month label with chevrons for prev/next and calendar icon
/// to open month picker sheet (§6 item 1).
class MonthHeader extends StatelessWidget {
  const MonthHeader({
    super.key,
    required this.year,
    required this.month,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
    required this.onCalendarTap,
  });

  final int year;
  final int month;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCalendarTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);
    final date = DateTime(year, month);
    final label = DateFormat('MMMM yyyy').format(date).toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
            iconSize: 22,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: colors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: styles.screenTitle,
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onCalendarTap,
            child: Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: hasNext ? onNext : null,
            icon: const Icon(Icons.chevron_right_rounded),
            iconSize: 22,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: hasNext ? colors.textSecondary : colors.borderHairline,
          ),
        ],
      ),
    );
  }
}