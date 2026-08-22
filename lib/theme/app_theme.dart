import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

ThemeData buildLightTheme() => _buildTheme(Brightness.light, AppColors.light);

ThemeData buildDarkTheme() => _buildTheme(Brightness.dark, AppColors.dark);

/// A slightly darker shade of [surface] for the app bar, so it reads as a
/// distinct header strip without introducing a shadow.
Color _appBarBackground(Color surface, Brightness brightness) {
  final amount = brightness == Brightness.light ? 0.04 : 0.12;
  return Color.lerp(surface, Colors.black, amount)!;
}

ThemeData _buildTheme(Brightness brightness, AppColors colors) {
  final textStyles = AppTextStyles(colors: colors);

  final baseTextTheme = TextTheme(
    displayLarge: textStyles.totalAmount,
    displayMedium: textStyles.onboardingTitle,
    headlineLarge: textStyles.screenTitle,
    titleLarge: textStyles.listRowTitle,
    titleMedium: textStyles.chipLabel,
    titleSmall: textStyles.sectionLabel,
    bodyLarge: textStyles.body,
    bodyMedium: textStyles.bodyTertiary,
    bodySmall: textStyles.caption,
    labelLarge: textStyles.button,
    labelMedium: textStyles.destructive,
    labelSmall: textStyles.pieLabel,
  ).apply(
    bodyColor: colors.textPrimary,
    displayColor: colors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: colors.textPrimary,
      onPrimary: colors.surfaceRaised,
      surface: colors.surfaceBase,
      onSurface: colors.textPrimary,
      error: colors.signalExpense,
      onError: colors.surfaceRaised,
      secondary: colors.textSecondary,
      onSecondary: colors.surfaceRaised,
      tertiary: colors.textTertiary,
      onTertiary: colors.surfaceRaised,
      outline: colors.borderHairline,
      outlineVariant: colors.borderHairline,
      shadow: Colors.transparent,
      scrim: Colors.black54,
      inverseSurface: colors.surfaceRaised,
      onInverseSurface: colors.textPrimary,
      inversePrimary: colors.textPrimary,
      surfaceTint: Colors.transparent,
    ),
    scaffoldBackgroundColor: colors.surfaceBase,
    textTheme: baseTextTheme,
    extensions: <ThemeExtension<dynamic>>[colors],
    appBarTheme: AppBarTheme(
      backgroundColor: _appBarBackground(colors.surfaceBase, brightness),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      iconTheme: IconThemeData(color: colors.textPrimary),
      titleTextStyle: textStyles.screenTitle,
    ),
    cardTheme: CardThemeData(
      color: colors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
        side: BorderSide(color: colors.borderHairline, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.textPrimary,
      foregroundColor: colors.surfaceRaised,
      elevation: 0,
      shape: const CircleBorder(),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusCard),
        ),
      ),
      showDragHandle: true,
      dragHandleColor: colors.borderHairline,
    ),
    dividerTheme: DividerThemeData(
      color: colors.borderHairline,
      thickness: 0.5,
      space: 0,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.surfaceRaised,
      contentTextStyle: textStyles.body,
      actionTextColor: colors.textPrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      ),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: colors.surfaceRaised,
      hourMinuteTextStyle: textStyles.totalAmount.copyWith(fontSize: 40),
      dayPeriodTextStyle: textStyles.body,
      dialHandColor: colors.textPrimary,
      dialBackgroundColor: colors.surfaceBase,
      entryModeIconColor: colors.textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceRaised,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        borderSide: BorderSide(color: colors.borderHairline, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        borderSide: BorderSide(color: colors.textPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        borderSide: BorderSide(color: colors.signalExpense, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      labelStyle: textStyles.body,
      hintStyle: textStyles.bodyTertiary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.textPrimary,
        foregroundColor: colors.surfaceRaised,
        elevation: 0,
        textStyle: textStyles.button,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.textPrimary,
        textStyle: textStyles.button,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.s,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textPrimary,
        textStyle: textStyles.button,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.s,
        ),
        side: BorderSide(color: colors.borderHairline, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      side: BorderSide(color: colors.borderHairline, width: 0.5),
      labelStyle: textStyles.chipLabel,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      ),
      brightness: brightness,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      titleTextStyle: textStyles.listRowTitle,
      subtitleTextStyle: textStyles.listRowSecondary,
      iconColor: colors.textPrimary,
      textColor: colors.textPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusChip),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.textPrimary,
      linearTrackColor: colors.borderHairline,
      circularTrackColor: colors.borderHairline,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: colors.textPrimary,
      inactiveTrackColor: colors.borderHairline,
      thumbColor: colors.textPrimary,
      overlayColor: colors.textPrimary.withValues(alpha: 0.12),
      valueIndicatorColor: colors.textPrimary,
      valueIndicatorTextStyle: textStyles.caption.copyWith(
        color: colors.surfaceRaised,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelStyle: textStyles.button,
      unselectedLabelStyle: textStyles.button.copyWith(
        color: colors.textTertiary,
      ),
      indicatorColor: colors.textPrimary,
      dividerColor: colors.borderHairline,
      labelColor: colors.textPrimary,
      unselectedLabelColor: colors.textTertiary,
    ),
  );
}