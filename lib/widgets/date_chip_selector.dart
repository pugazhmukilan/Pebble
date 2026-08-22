import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Date chip row — Today / Yesterday / 2d / 3d / Custom (§7).
/// Pill-shaped chips per §11 component language.
class DateChipSelector extends StatelessWidget {
  const DateChipSelector({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final chips = <_DateChip>[
      _DateChip('Today', today),
      _DateChip('Yesterday', today.subtract(const Duration(days: 1))),
    ];

    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final isCustom = !chips.any((c) => c.date == selectedDay);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...chips.map(
            (chip) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildChip(
                context: context,
                colors: colors,
                styles: styles,
                label: chip.label,
                selected: chip.date == selectedDay,
                onTap: () => onDateSelected(chip.date),
              ),
            ),
          ),
          _buildChip(
            context: context,
            colors: colors,
            styles: styles,
            label: isCustom
                ? '${selectedDate.day}/${selectedDate.month}'
                : 'Custom',
            selected: isCustom,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: today,
              );
              if (picked != null) onDateSelected(picked);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required BuildContext context,
    required AppColors colors,
    required AppTextStyles styles,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.textPrimary : colors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
          border: Border.all(
            color: selected ? colors.textPrimary : colors.borderHairline,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: styles.chipLabel.copyWith(
            color: selected ? colors.surfaceRaised : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _DateChip {
  const _DateChip(this.label, this.date);
  final String label;
  final DateTime date;
}