import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../constants/category_colors.dart';
import '../constants/category_icons.dart';
import '../models/category.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
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

/// Bottom sheet to add or edit a category — name and icon (emoji or Material).
/// Category color is assigned automatically from the 20-color pool (§5.5);
/// there is no user-facing color control (§7.10).
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
  bool _poolExhausted = false;

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
    if (cat != null) {
      // Editing: keep the existing fixed color.
      _colorValue = cat.colorValue;
    } else {
      // New: auto-assign a pool color (§5.5).
      final used = widget.existingCategories.map((c) => c.colorValue).toList();
      final index = allocateColorIndex(used);
      if (index == null) {
        _poolExhausted = true;
        _colorValue = 0;
      } else {
        _colorValue = poolColorValue(index);
      }
    }
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

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && !_poolExhausted;

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

    if (_poolExhausted) {
      _showLimitMessage();
      return;
    }

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
        iconCodePoint:
            iconCode ?? existing?.iconCodePoint ?? Icons.star_rounded.codePoint,
        emoji: emoji,
        colorValue: _colorValue,
      ),
    );
  }

  void _showLimitMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("You've reached the 20 category limit."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final styles = AppTextStyles.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.xs,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
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
                      style: styles.screenTitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Name field with duplicate validation
                    TextField(
                      controller: _nameController,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Category name',
                        errorText: _nameError,
                        filled: true,
                        fillColor: colors.surfaceRaised,
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(AppSpacing.radiusChip),
                          ),
                          borderSide: BorderSide.none,
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(AppSpacing.radiusChip),
                          ),
                          borderSide: BorderSide(color: colors.signalExpense),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(AppSpacing.radiusChip),
                          ),
                          borderSide: BorderSide(color: colors.signalExpense),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Icon type toggle
                    Text('ICON', style: styles.sectionLabel),
                    const SizedBox(height: AppSpacing.sm),
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
                    const SizedBox(height: AppSpacing.sm),

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
                    const SizedBox(height: AppSpacing.lg),

                    // Assigned color — informational only (§7.10). No picker.
                    Text('COLOR', style: styles.sectionLabel),
                    const SizedBox(height: AppSpacing.sm),
                    if (_poolExhausted)
                      Text(
                        "You've reached the 20 category limit.",
                        style: styles.destructive,
                      )
                    else
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Color(_colorValue),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusChip),
                              border: Border.all(color: colors.borderHairline),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Assigned automatically',
                            style: styles.caption,
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.lg),
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
                      ? colors.textPrimary
                      : colors.textTertiary,
                  foregroundColor: colors.surfaceRaised,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusChip),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _isEditing ? 'Save changes' : 'Add category',
                  style: styles.button,
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
    final colors = AppColors.of(context);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onToggle(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isEmoji ? colors.textPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Emoji',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isEmoji ? colors.surfaceRaised : colors.textSecondary,
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
                  color: !isEmoji ? colors.textPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Icons',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: !isEmoji ? colors.surfaceRaised : colors.textSecondary,
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
    final colors = AppColors.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
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
                  ? colors.textPrimary.withValues(alpha: 0.08)
                  : colors.surfaceRaised,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? colors.textPrimary : colors.borderHairline,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
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
    final colors = AppColors.of(context);

    return SizedBox(
      height: 200,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemCount: kMaterialCategoryIcons.length,
        itemBuilder: (context, index) {
          final icon = kMaterialCategoryIcons[index];
          final selected = selectedCodePoint == icon.codePoint;
          return GestureDetector(
            onTap: () => onSelected(icon.codePoint),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: selected
                    ? colors.textPrimary.withValues(alpha: 0.08)
                    : colors.surfaceRaised,
                borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
                border: Border.all(
                  color: selected ? colors.textPrimary : colors.borderHairline,
                  width: selected ? 1.5 : 0.5,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          );
        },
      ),
    );
  }
}
