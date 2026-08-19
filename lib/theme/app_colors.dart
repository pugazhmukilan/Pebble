import 'package:flutter/material.dart';

/// Design tokens from spec §11 — Apple-influenced, monochrome-first.
abstract final class AppColors {
  // Backgrounds
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundAlt = Color(0xFFFAFAFA);

  // Surface / card
  static const Color surface = Color(0xFFF5F5F7);
  static const Color border = Color(0xFFE5E5EA);

  // Text
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textMuted = Color(0xFF8E8E93);

  // Accent — near-black, per spec
  static const Color accent = Color(0xFF1C1C1E);
  static const Color accentDisabled = Color(0xFFC7C7CC);

  // Destructive (delete actions)
  static const Color destructive = Color(0xFFFF3B30);
}
