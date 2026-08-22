import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles({required AppColors colors}) : _colors = colors;

  static AppTextStyles of(BuildContext context) =>
      AppTextStyles(colors: AppColors.of(context));

  final AppColors _colors;

  TextStyle get _base => TextStyle(
        fontFamily: 'Inter',
        color: _colors.textPrimary,
        fontWeight: FontWeight.w400,
      );

  TextStyle get totalAmount => _base.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: _colors.textPrimary,
      );

  TextStyle get screenTitle => _base.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _colors.textPrimary,
      );

  TextStyle get sectionLabel => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: _colors.textSecondary,
      );

  TextStyle get listRowTitle => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: _colors.textPrimary,
      );

  TextStyle get listRowSecondary => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: _colors.textSecondary,
      );

  TextStyle get body => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _colors.textSecondary,
      );

  TextStyle get bodyTertiary => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _colors.textTertiary,
      );

  TextStyle get caption => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: _colors.textTertiary,
      );

  TextStyle get chipLabel => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _colors.textSecondary,
      );

  TextStyle get button => _base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: _colors.surfaceRaised,
      );

  TextStyle get onboardingTitle => _base.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w600,
        color: _colors.textPrimary,
      );

  TextStyle get onboardingBody => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _colors.textSecondary,
      );

  TextStyle get cardLabel => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: _colors.textTertiary,
      );

  TextStyle get pieLabel => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: _colors.textSecondary,
      );

  TextStyle get slicePercent => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: _colors.surfaceRaised,
      );

  TextStyle get destructive => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _colors.signalExpense,
      );
}