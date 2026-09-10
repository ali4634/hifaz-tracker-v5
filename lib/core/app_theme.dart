import 'package:flutter/material.dart';

import 'app_colors.dart';

/// App-wide theme factory: dark & light glassmorphic themes.
///
/// Fonts are bundled locally (see pubspec `fonts:`) so the app renders
/// correctly even fully offline — no runtime font fetching.
class AppTheme {
  AppTheme._();

  /// Bundled font family names (declared in pubspec).
  static const String latinFamily = 'Outfit';
  static const String urduFamily = 'JameelNooriNastaleeq';

  /// Main Latin font.
  static TextStyle latinFont({
    FontWeight weight = FontWeight.w400,
    double? size,
    Color? color,
    double? height,
  }) => TextStyle(
    fontFamily: latinFamily,
    fontWeight: weight,
    fontSize: size,
    color: color,
    height: height,
  );

  /// Urdu / Arabic friendly font (Jameel Noori Nastaleeq — the classic,
  /// highly readable Urdu script used by v4).
  ///
  /// NOTE: Jameel Noori Nastaleeq ships as a single Regular weight; Flutter
  /// does not synthesize bold, so [weight] requests render at Regular — the
  /// same behaviour v4 had with this font.
  static TextStyle urduFont({
    FontWeight weight = FontWeight.w400,
    double? size,
    Color? color,
    double? height,
  }) => TextStyle(
    fontFamily: urduFamily,
    fontWeight: weight,
    fontSize: size,
    color: color,
    height: height,
  );

  /// Builds the dark theme for [accent] ('emerald' or 'amber').
  ///
  /// Note: the active brightness for the theme-aware [AppColors] getters is
  /// set by `HifazApp` (it resolves `system` mode); it is not set here because
  /// MaterialApp eagerly builds *both* themes on every rebuild.
  static ThemeData dark({String accent = AppColors.accentEmerald}) {
    AppColors.accent = accent;
    return _build(
      brightness: Brightness.dark,
      scaffold: AppColors.bgBase,
      surfaceFill: AppColors.glassFillStrong,
      borderColor: AppColors.glassBorder,
      primaryText: AppColors.textPrimary,
      secondaryText: AppColors.textSecondary,
    );
  }

  /// Builds the light theme for [accent] ('emerald' or 'amber').
  static ThemeData light({String accent = AppColors.accentEmerald}) {
    AppColors.accent = accent;
    return _build(
      brightness: Brightness.light,
      scaffold: AppColors.lightBg,
      surfaceFill: AppColors.lightGlassFill,
      borderColor: AppColors.lightGlassBorder,
      primaryText: AppColors.lightText,
      secondaryText: AppColors.lightTextSecondary,
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surfaceFill,
    required Color borderColor,
    required Color primaryText,
    required Color secondaryText,
  }) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      surface: isDark ? AppColors.bgBase : AppColors.lightBg,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: urduFamily,
    );

    // fontFamily is already applied to the whole text theme via
    // ThemeData(fontFamily: latinFamily) above.
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: primaryText,
        displayColor: primaryText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: primaryText,
        titleTextStyle: latinFont(
          size: 22,
          weight: FontWeight.w700,
          color: primaryText,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.bgElevated : AppColors.lightBg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.bgElevated : Colors.white,
        contentTextStyle: TextStyle(color: primaryText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerColor: borderColor,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceFill,
        hintStyle: TextStyle(color: secondaryText.withValues(alpha: 0.7)),
        labelStyle: TextStyle(color: secondaryText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : primaryText,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.35)
              : borderColor,
        ),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(),
      listTileTheme: ListTileThemeData(iconColor: primaryText),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: isDark ? AppColors.bgElevated : AppColors.lightBg,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: AppColors.primary.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: isDark ? AppColors.bgElevated : AppColors.lightBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: borderColor,
      ),
    );
  }
}
