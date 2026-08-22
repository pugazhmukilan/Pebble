import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.surfaceBase,
    required this.surfaceRaised,
    required this.borderHairline,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.signalIncome,
    required this.signalExpense,
    required this.categoryOther,
  });

  final Color surfaceBase;
  final Color surfaceRaised;
  final Color borderHairline;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color signalIncome;
  final Color signalExpense;
  final Color categoryOther;

  static const AppColors light = AppColors(
    surfaceBase: Color(0xFFF7F9FB),
    surfaceRaised: Color(0xFFFFFFFF),
    borderHairline: Color(0xFFDCE4EF),
    textPrimary: Color(0xFF1C2E4A),
    textSecondary: Color(0xFF52677D),
    textTertiary: Color(0xFFA0ADC2),
    signalIncome: Color(0xFF2E7D5B),
    signalExpense: Color(0xFFB54B3C),
    categoryOther: Color(0xFF9BA3AE),
  );

  static const AppColors dark = AppColors(
    surfaceBase: Color(0xFF1B1E22),
    surfaceRaised: Color(0xFF2A2F35),
    borderHairline: Color(0xFF4A5156),
    textPrimary: Color(0xFFE7EAEC),
    textSecondary: Color(0xFF808A92),
    textTertiary: Color(0xFF5C646B),
    signalIncome: Color(0xFF4ADE9B),
    signalExpense: Color(0xFFE5786A),
    categoryOther: Color(0xFF6B7278),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  @override
  AppColors copyWith({
    Color? surfaceBase,
    Color? surfaceRaised,
    Color? borderHairline,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? signalIncome,
    Color? signalExpense,
    Color? categoryOther,
  }) {
    return AppColors(
      surfaceBase: surfaceBase ?? this.surfaceBase,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      borderHairline: borderHairline ?? this.borderHairline,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      signalIncome: signalIncome ?? this.signalIncome,
      signalExpense: signalExpense ?? this.signalExpense,
      categoryOther: categoryOther ?? this.categoryOther,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      surfaceBase: Color.lerp(surfaceBase, other.surfaceBase, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      borderHairline: Color.lerp(borderHairline, other.borderHairline, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      signalIncome: Color.lerp(signalIncome, other.signalIncome, t)!,
      signalExpense: Color.lerp(signalExpense, other.signalExpense, t)!,
      categoryOther: Color.lerp(categoryOther, other.categoryOther, t)!,
    );
  }
}