import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Modal bottom sheet to jump directly to any month/year (§6 item 1).
/// Future months are disabled.
class MonthPickerSheet extends StatefulWidget {
  const MonthPickerSheet({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  final int selectedYear;
  final int selectedMonth;
  final void Function(int year, int month) onMonthSelected;

  @override
  State<MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<MonthPickerSheet> {
  late int _year;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.selectedYear;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Year selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => setState(() => _year--),
                icon: const Icon(Icons.chevron_left_rounded),
                color: AppColors.textMuted,
              ),
              Text('$_year', style: AppTextStyles.monthHeader),
              IconButton(
                onPressed: () => setState(() => _year++),
                icon: const Icon(Icons.chevron_right_rounded),
                color: AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Month grid
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2,
            children: List.generate(12, (index) {
              final month = index + 1;
              final isSelected =
                  _year == widget.selectedYear && month == widget.selectedMonth;
              final now = DateTime.now();
              final isFuture =
                  _year > now.year || (_year == now.year && month > now.month);

              return GestureDetector(
                onTap: isFuture
                    ? null
                    : () {
                        widget.onMonthSelected(_year, month);
                        Navigator.of(context).pop();
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _months[index],
                    style: AppTextStyles.chipLabel.copyWith(
                      color: isFuture
                          ? AppColors.accentDisabled
                          : isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
