import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Text styles using system font stack (Roboto on Android, SF Pro on iOS).
/// Tabular figures for numeric alignment per spec §11.
abstract final class AppTextStyles {
  // Large total display
  static const TextStyle totalAmount = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // Month header
  static const TextStyle monthHeader = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  // Section header (day groups in expense list)
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );

  // Expense row — category label
  static const TextStyle expenseLabel = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Expense row — note text
  static const TextStyle expenseNote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  // Expense row — amount
  static const TextStyle expenseAmount = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // Amount keypad display
  static const TextStyle keypadDisplay = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w300,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // Pill chip label
  static const TextStyle chipLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // Button text
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Small caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );

  // Onboarding — title
  static const TextStyle onboardingTitle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  // Onboarding — body
  static const TextStyle onboardingBody = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.5,
  );

  // Card label (e.g. "Total spent")
  static const TextStyle cardLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  // Pie chart legend label
  static const TextStyle pieLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );
}
