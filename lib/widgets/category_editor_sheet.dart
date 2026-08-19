import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

const List<String> _categoryEmojis = [
  '🍽️', '🍕', '🍔', '🍜', '🍣', '☕', '🍰',
  '🛒', '👕', '👟', '💄', '💍',
  '🚗', '🚕', '✈️', '🚆', '🚲', '⛽',
  '🏠', '🛏️', '💡', '💧',
  '📱', '📄', '💰', '🏦',
  '💊', '🏥', '❤️', '🏃',
  '🎬', '🎮', '🎧', '⚽', '🎲',
  '🐶', '🎓', '💼', '📦', '⭐', '✨',
];

const List<IconData> _materialIcons = [
  Icons.restaurant_rounded, Icons.coffee_rounded, Icons.local_pizza_rounded,
  Icons.lunch_dining_rounded, Icons.icecream_rounded, Icons.local_bar_rounded,
  Icons.shopping_bag_rounded, Icons.shopping_cart_rounded, Icons.store_rounded,
  Icons.checkroom_rounded, Icons.face_rounded, Icons.brush_rounded,
  Icons.directions_car_rounded, Icons.two_wheeler_rounded, Icons.flight_rounded,
  Icons.directions_bus_rounded, Icons.train_rounded, Icons.local_gas_station_rounded,
  Icons.home_rounded, Icons.king_bed_rounded, Icons.light_rounded,
  Icons.water_drop_rounded, Icons.foundation_rounded, Icons.fence_rounded,
  Icons.phone_rounded, Icons.laptop_rounded, Icons.headphones_rounded,
  Icons.camera_alt_rounded, Icons.smartphone_rounded, Icons.tablet_rounded,
  Icons.attach_money_rounded, Icons.account_balance_rounded, Icons.savings_rounded,
  Icons.receipt_long_rounded, Icons.credit_card_rounded, Icons.payments_rounded,
  Icons.favorite_rounded, Icons.local_hospital_rounded, Icons.medical_services_rounded,
  Icons.fitness_center_rounded, Icons.spa_rounded, Icons.monitor_heart_rounded,
  Icons.sports_esports_rounded, Icons.movie_rounded, Icons.music_note_rounded,
  Icons.sports_football_rounded, Icons.palette_rounded, Icons.brush_rounded,
  Icons.school_rounded, Icons.menu_book_rounded, Icons.science_rounded,
  Icons.build_rounded, Icons.engineering_rounded, Icons.architecture_rounded,
  Icons.pets_rounded, Icons.catching_pokemon_rounded, Icons.eco_rounded,
  Icons.flight_takeoff_rounded, Icons.map_rounded, Icons.beach_access_rounded,
  Icons.workspace_premium_rounded, Icons.emoji_events_rounded, Icons.star_rounded,
  Icons.workspace_premium_rounded, Icons.card_giftcard_rounded, Icons.celebration_rounded,
  Icons.notifications_rounded, Icons.mail_rounded, Icons.chat_rounded,
  Icons.bookmark_rounded, Icons.flag_rounded, Icons.push_pin_rounded,
];

/// Default color for a newly created category.
const int _defaultCategoryColor = 0xFF64B5F6;

/// Bottom sheet to add or edit a category — name, icon (emoji or Material), and color.
/// Pops with the composed [ExpenseCategory] on save (null when cancelled).
class CategoryEditorSheet extends StatefulWidget {
  const CategoryEditorSheet({
    super.key,
    this.category,
    this.existingCategories = const [],
  });

  final ExpenseCategory? category;
  final List<ExpenseCategory> existingCategories;

  @override
  State<CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<CategoryEditorSheet> {
  late final TextEditingController _nameController;
  late String? _emoji;
  late int? _iconCodePoint;
  late bool _useEmoji;
  late int _colorValue;
  String? _nameError;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _nameController = TextEditingController(text: cat?.label ?? '');
    _emoji = cat?.emoji;
    _useEmoji = cat?.emoji != null;
    if (cat != null && cat.emoji == null) {
      _iconCodePoint = cat.iconCodePoint;
    } else {
      _iconCodePoint = Icons.star_rounded.codePoint;
    }
    _colorValue = cat?.colorValue ?? _defaultCategoryColor;
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (_nameError != null) {
      setState(() => _nameError = null);
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  bool _isDuplicateName(String name) {
    final lower = name.toLowerCase();
    return widget.existingCategories.any(
      (c) =>
          c.label.toLowerCase() == lower &&
          c.id != widget.category?.id,
    );
  }

  void _save() {
    final label = _nameController.text.trim();
    if (label.isEmpty) return;

    if (_isDuplicateName(label)) {
      setState(() => _nameError = 'A category with this name already exists');
      return;
    }

    final existing = widget.category;
    final emoji = _useEmoji ? _emoji : null;
    final iconCode = _useEmoji ? null : _iconCodePoint;

    Navigator.of(context).pop(
      ExpenseCategory(
        id: existing?.id ?? const Uuid().v4(),
        label: label,
        iconCodePoint: iconCode ?? existing?.iconCodePoint ?? Icons.star_rounded.codePoint,
        emoji: emoji,
        colorValue: _colorValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isEditing ? 'Edit Category' : 'New Category',
                      style: AppTextStyles.monthHeader,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Name field with duplicate validation
                    TextField(
                      controller: _nameController,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Category name',
                        errorText: _nameError,
                        filled: true,
                        fillColor: AppColors.surface,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide.none,
                        ),
                        errorBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: AppColors.destructive),
                        ),
                        focusedErrorBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          borderSide: BorderSide(color: AppColors.destructive),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Icon type toggle
                    const Text('ICON', style: AppTextStyles.sectionHeader),
                    const SizedBox(height: 10),
                    _IconTypeToggle(
                      isEmoji: _useEmoji,
                      onToggle: (isEmoji) {
                        setState(() {
                          _useEmoji = isEmoji;
                          if (!isEmoji && _iconCodePoint == null) {
                            _iconCodePoint = Icons.star_rounded.codePoint;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    // Icon picker (emoji or material)
                    if (_useEmoji)
                      _EmojiPicker(
                        selectedEmoji: _emoji,
                        onSelected: (emoji) =>
                            setState(() => _emoji = emoji),
                      )
                    else
                      _MaterialIconPicker(
                        selectedCodePoint: _iconCodePoint,
                        onSelected: (codePoint) =>
                            setState(() => _iconCodePoint = codePoint),
                      ),
                    const SizedBox(height: 20),

                    // Color picker — MS Word style
                    const Text('COLOR', style: AppTextStyles.sectionHeader),
                    const SizedBox(height: 10),
                    _ColorPicker(
                      selectedColorValue: _colorValue,
                      onColorSelected: (color) =>
                          setState(() => _colorValue = color),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _canSave ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSave
                      ? AppColors.accent
                      : AppColors.accentDisabled,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.accentDisabled,
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _isEditing ? 'Save changes' : 'Add category',
                  style: AppTextStyles.button,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Toggle between Emoji and Material Icon modes.
class _IconTypeToggle extends StatelessWidget {
  const _IconTypeToggle({required this.isEmoji, required this.onToggle});

  final bool isEmoji;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isEmoji ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Emoji',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isEmoji ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !isEmoji ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Icons',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: !isEmoji ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Emoji grid picker.
class _EmojiPicker extends StatelessWidget {
  const _EmojiPicker({required this.selectedEmoji, required this.onSelected});

  final String? selectedEmoji;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categoryEmojis.map((emoji) {
        final selected = selectedEmoji == emoji;
        return GestureDetector(
          onTap: () => onSelected(emoji),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.08)
                  : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.accent : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        );
      }).toList(),
    );
  }
}

/// Material icon grid picker, organized by category.
class _MaterialIconPicker extends StatelessWidget {
  const _MaterialIconPicker({
    required this.selectedCodePoint,
    required this.onSelected,
  });

  final int? selectedCodePoint;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemCount: _materialIcons.length,
        itemBuilder: (context, index) {
          final icon = _materialIcons[index];
          final selected = selectedCodePoint == icon.codePoint;
          return GestureDetector(
            onTap: () => onSelected(icon.codePoint),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent.withValues(alpha: 0.08)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.border,
                  width: selected ? 1.5 : 0.5,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? AppColors.accent : AppColors.textMuted,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Draggable HSV color picker — a saturation/value square plus a hue slider,
/// so the user can drag to any shade. Keeps a small recent-colors row.
class _ColorPicker extends StatefulWidget {
  const _ColorPicker({
    required this.selectedColorValue,
    required this.onColorSelected,
  });

  final int selectedColorValue;
  final ValueChanged<int> onColorSelected;

  @override
  State<_ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<_ColorPicker> {
  double _hue = 0;
  double _saturation = 1;
  double _value = 1;
  bool _interacting = false;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant _ColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interacting) _syncFromWidget();
  }

  /// Sync internal HSV from the widget's currently selected color.
  void _syncFromWidget() {
    final hsv = HSVColor.fromColor(Color(widget.selectedColorValue));
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  Color get _currentColor =>
      HSVColor.fromAHSV(1, _hue, _saturation, _value).toColor();

  /// Push the current color up to the parent.
  void _commit() {
    widget.onColorSelected(_currentColor.toARGB32());
  }

  void _updateSaturationValue(Offset pos, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    setState(() {
      _interacting = true;
      _saturation = (pos.dx / size.width).clamp(0.0, 1.0).toDouble();
      _value = (1 - pos.dy / size.height).clamp(0.0, 1.0).toDouble();
    });
    _commit();
  }

  void _updateHue(double dx, double width) {
    if (width <= 0) return;
    setState(() {
      _interacting = true;
      _hue = (dx / width * 360).clamp(0.0, 360.0).toDouble();
    });
    _commit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Saturation / value square
        _buildSVPanel(),

        const SizedBox(height: 14),

        // Hue slider
        _buildHueSlider(),

        const SizedBox(height: 14),

        // Current color preview
        _buildPreview(),
      ],
    );
  }

  Widget _buildSVPanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 180.0;
        return GestureDetector(
          onTapDown: (d) =>
              _updateSaturationValue(d.localPosition, Size(width, height)),
          onPanDown: (d) =>
              _updateSaturationValue(d.localPosition, Size(width, height)),
          onPanUpdate: (d) =>
              _updateSaturationValue(d.localPosition, Size(width, height)),
          onPanEnd: (_) => _interacting = false,
          onPanCancel: () => _interacting = false,
          child: SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CustomPaint(
                painter: _SaturationValuePainter(_hue),
                child: Stack(
                  children: [
                    Positioned(
                      left: _saturation * width - 12,
                      top: (1 - _value) * height - 12,
                      child: _handle(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHueSlider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 24.0;
        return GestureDetector(
          onTapDown: (d) => _updateHue(d.localPosition.dx, width),
          onPanDown: (d) => _updateHue(d.localPosition.dx, width),
          onPanUpdate: (d) => _updateHue(d.localPosition.dx, width),
          onPanEnd: (_) => _interacting = false,
          onPanCancel: () => _interacting = false,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(height / 2),
                  child: CustomPaint(
                    painter: const _HuePainter(),
                    size: Size(width, height),
                  ),
                ),
                Positioned(
                  left: _hue / 360 * width - 12,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppColors.accent, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreview() {
    final hex =
        '#${(_currentColor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _currentColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hex, style: AppTextStyles.chipLabel),
              Text(
                'Drag the square and hue bar to pick any shade',
                style: AppTextStyles.caption,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _handle() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentColor,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

/// Paints the saturation/value square for a given hue:
/// white → hue horizontally, transparent → black vertically.
class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter(this.hue);

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    final horizontal = ui.Gradient.linear(
      Offset.zero,
      Offset(size.width, 0),
      [Colors.white, hueColor],
    );
    canvas.drawRect(rect, Paint()..shader = horizontal);
    final vertical = ui.Gradient.linear(
      Offset.zero,
      Offset(0, size.height),
      [Colors.transparent, Colors.black],
    );
    canvas.drawRect(rect, Paint()..shader = vertical);
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) =>
      oldDelegate.hue != hue;
}

/// Paints the rainbow hue bar (red → yellow → green → cyan → blue → magenta).
class _HuePainter extends CustomPainter {
  const _HuePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final colors = <Color>[
      const Color(0xFFFF0000),
      const Color(0xFFFFFF00),
      const Color(0xFF00FF00),
      const Color(0xFF00FFFF),
      const Color(0xFF0000FF),
      const Color(0xFFFF00FF),
      const Color(0xFFFF0000),
    ];
    final stops =
        List.generate(colors.length, (i) => i / (colors.length - 1));
    final shader = ui.Gradient.linear(
      Offset.zero,
      Offset(size.width, 0),
      colors,
      stops,
    );
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _HuePainter oldDelegate) => false;
}
