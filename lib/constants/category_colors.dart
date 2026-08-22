import 'package:flutter/material.dart';

/// The canonical 20-color pool (light-mode base values, §5.1).
/// Index in this list == pool index used for assignment (§5.5).
const List<Color> kCategoryColorPool = [
  Color(0xFF4E6E9E),
  Color(0xFF5A82B0),
  Color(0xFF6366A6),
  Color(0xFF7B6FBE),
  Color(0xFF8A6A9E),
  Color(0xFF9C6B84),
  Color(0xFFAD7A94),
  Color(0xFF4C8577),
  Color(0xFF5FA093),
  Color(0xFF3F6B72),
  Color(0xFFB8935A),
  Color(0xFFC9A96E),
  Color(0xFFA68A4A),
  Color(0xFF8A8558),
  Color(0xFF6D7A4A),
  Color(0xFF7A6249),
  Color(0xFF6A7BA8),
  Color(0xFFC48FA0),
  Color(0xFFD1B27A),
  Color(0xFF556B8A),
];

/// Reserved, system-only "Other" category id (§1.3). Never user assigned,
/// edited, renamed, deleted, or part of the 20-color pool.
const String kOtherCategoryId = 'other';

/// The fixed light-mode color for the reserved Other category.
const Color kOtherColorLight = Color(0xFF9BA3AE);

/// Derives a dark-mode variant of [base] by lifting lightness +0.18 (capped
/// at 0.72), as specified by the formula in §5.2. Computed lazily and
/// memoized — never recomputed on every frame.
final Map<int, Color> _darkVariantCache = {};

Color darkVariantOf(Color base) {
  final key = base.toARGB32();
  final cached = _darkVariantCache[key];
  if (cached != null) return cached;

  final hsl = HSLColor.fromColor(base);
  final lifted = (hsl.lightness + 0.18).clamp(0.0, 0.72);
  final result = hsl.withLightness(lifted).toColor();
  _darkVariantCache[key] = result;
  return result;
}

/// Resolves the display color for a stored [colorValue] given the active
/// brightness. Light mode returns the stored base; dark mode applies the
/// §5.2 derivation. Used ONLY in the two chart contexts named in §5.3 —
/// never for icon chips, list rows, or the quick-add grid.
Color resolveCategoryColor(
  BuildContext context,
  int colorValue, {
  bool isOther = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (isOther || isDark) {
    final base = Color(colorValue);
    if (!isDark) return base; // Other light base is already correct
    return darkVariantOf(base);
  }
  return Color(colorValue);
}

/// Picks a pool index for a new category via the §5.5 algorithm.
/// Returns null when all 20 colors are already assigned (hard cap, §5.6).
int? allocateColorIndex(List<int> usedBaseValues) {
  final usedIndices = <int>{};
  for (final value in usedBaseValues) {
    final idx = kCategoryColorPool.indexWhere((c) => c.toARGB32() == value);
    if (idx != -1) usedIndices.add(idx);
  }
  if (usedIndices.length >= kCategoryColorPool.length) return null;
  final available = <int>{};
  for (var i = 0; i < kCategoryColorPool.length; i++) {
    available.add(i);
  }
  available.removeAll(usedIndices);
  return available.elementAt(
    DateTime.now().microsecondsSinceEpoch % available.length,
  );
}

/// Returns the ARGB int of a pool color at [index] for light mode storage.
int poolColorValue(int index) => kCategoryColorPool[index].toARGB32();
