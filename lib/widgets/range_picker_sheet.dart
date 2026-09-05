import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Bottom-sheet month-range picker for the analysis "Custom" range.
///
/// Tap a start month, then an end month. Tapping again after both are set
/// begins a fresh selection. Future months (after [maxMonth]) are disabled.
class RangePickerSheet extends StatefulWidget {
  const RangePickerSheet({
    super.key,
    required this.initialStart,
    required this.initialEnd,
    required this.minMonth,
    required this.maxMonth,
    required this.onApply,
  });

  final DateTime initialStart;
  final DateTime initialEnd;
  final DateTime minMonth;
  final DateTime maxMonth;
  final void Function(DateTime start, DateTime end) onApply;

  @override
  State<RangePickerSheet> createState() => _RangePickerSheetState();
}

class _RangePickerSheetState extends State<RangePickerSheet> {
  late DateTime _start;
  late DateTime? _end;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  bool _isSelectable(DateTime month) {
    final m = DateTime(month.year, month.month);
    final min = DateTime(widget.minMonth.year, widget.minMonth.month);
    final max = DateTime(widget.maxMonth.year, widget.maxMonth.month);
    return !m.isBefore(min) && !m.isAfter(max);
  }

  bool _isFuture(DateTime month) {
    final m = DateTime(month.year, month.month);
    final max = DateTime(widget.maxMonth.year, widget.maxMonth.month);
    return m.isAfter(max);
  }

  void _onTap(DateTime month) {
    if (_isFuture(month)) return;
    setState(() {
      if (_end == null) {
        // Choosing the end of the range.
        if (month.isBefore(_start)) {
          _end = _start;
          _start = month;
        } else {
          _end = month;
        }
      } else {
        // Both were set → start a new selection.
        _start = month;
        _end = null;
      }
    });
  }

  Color _chipColor(DateTime month, AppColors colors) {
    final m = DateTime(month.year, month.month);
    final start = DateTime(_start.year, _start.month);
    final end = _end == null
        ? null
        : DateTime(_end!.year, _end!.month);

    if (end != null) {
      final inRange = !m.isBefore(start) && !m.isAfter(end);
      if (m == start || m == end) return colors.textPrimary;
      if (inRange) return colors.textPrimary.withValues(alpha: 0.14);
    } else if (m == start) {
      return colors.textPrimary;
    }
    return colors.surfaceRaised;
  }

  Color _chipTextColor(DateTime month, AppColors colors) {
    final m = DateTime(month.year, month.month);
    final start = DateTime(_start.year, _start.month);
    final end = _end == null
        ? null
        : DateTime(_end!.year, _end!.month);
    final selected = end == null
        ? m == start
        : (m == start || m == end || (!m.isBefore(start) && !m.isAfter(end)));
    if (_isFuture(month)) return colors.textTertiary;
    return selected ? colors.surfaceRaised : colors.textPrimary;
  }

  Widget _monthChip(int year, int month, AppColors colors, AppTextStyles styles) {
    final date = DateTime(year, month);
    final enabled = _isSelectable(date) && !_isFuture(date);
    return GestureDetector(
      onTap: enabled ? () => _onTap(date) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? _chipColor(date, colors) : colors.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled
                ? (_chipTextColor(date, colors) == colors.textPrimary
                    ? colors.borderHairline
                    : _chipColor(date, colors))
                : colors.borderHairline,
            width: 0.5,
          ),
        ),
        child: Text(
          _months[month - 1],
          style: styles.chipLabel.copyWith(
            color: enabled ? _chipTextColor(date, colors) : colors.textTertiary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    // Build a year-by-year list of month chips, newest (current) first.
    final years = <int>[];
    for (var y = widget.maxMonth.year; y >= widget.minMonth.year; y--) {
      years.add(y);
    }

    final canApply = _end != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Text(
            'Custom range',
            textAlign: TextAlign.center,
            style: styles.screenTitle,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _end == null
                  ? 'Tap a start month'
                  : 'Tap a start, then an end month',
              textAlign: TextAlign.center,
              style: styles.caption,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SizedBox(
              height: 380,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final year in years) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '$year',
                        style: styles.chipLabel.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.2,
                      children: [
                        for (var month = 12; month >= 1; month--)
                          _monthChip(year, month, colors, styles),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canApply
                    ? () => widget.onApply(_start, _end!)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.textPrimary,
                  foregroundColor: colors.surfaceRaised,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusChip),
                  ),
                ),
                child: Text(
                  _end == null
                      ? 'Select an end month'
                      : 'Show ${_months[_start.month - 1]} '
                          '${_start.year} – ${_months[_end!.month - 1]} '
                          '${_end!.year}',
                  style: styles.button,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
