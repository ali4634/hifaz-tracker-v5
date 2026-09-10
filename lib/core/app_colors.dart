import 'package:flutter/material.dart';

/// Central color palette for the Hifaz Tracker glassmorphic design system.
///
/// Colors are split into two accents — `emerald` (default) and `amber` (gold).
/// Accent-sensitive colors are exposed as getters that follow the currently
/// active [accent], so the whole UI restyles when the user changes it in
/// Settings. The active accent is set by `AppTheme` before building themes.
///
/// Several colors are also *brightness-aware*: `textPrimary`, `textSecondary`,
/// `textMuted` and the `glass*` surfaces return a dark or a light value
/// depending on the active brightness (set by `HifazApp` via
/// [setBrightness] after resolving the `themeMode`). Widgets can therefore
/// reference `AppColors.textSecondary` directly and still render correctly in
/// both themes.
class AppColors {
  AppColors._();

  // ── Active accent ─────────────────────────────────────────────────────────
  static const String accentEmerald = 'emerald';
  static const String accentAmber = 'amber';

  /// Currently active accent; 'emerald' by default. Set by [AppTheme].
  static String accent = accentEmerald;

  // ── Active brightness ─────────────────────────────────────────────────────
  static bool _isDark = true;

  /// Whether the currently active theme is dark. Set by [AppTheme] before
  /// building a theme, so theme-aware getters return the right palette.
  static bool get isDark => _isDark;

  static void setBrightness(Brightness brightness) =>
      _isDark = brightness == Brightness.dark;

  // ── Emerald palette (default) ─────────────────────────────────────────────
  static const Color emeraldPrimary = Color(0xFF10B981);
  static const Color emeraldPrimarySoft = Color(0xFF34D399);
  static const Color emeraldGradA = Color(0xFF10B981);
  static const Color emeraldGradB = Color(0xFF059669);
  static const Color emeraldWarning = Color(0xFFF59E0B);
  static const Color emeraldBgBase = Color(0xFF0F172A);
  static const Color emeraldBgDeep = Color(0xFF0B1120);
  static const Color emeraldBgElevated = Color(0xFF1E293B);
  static const Color emeraldLightBg = Color(0xFFF1F5F9);
  static const Color emeraldLightBgDeep = Color(0xFFE2E8F0);

  // ── Amber Gold palette ────────────────────────────────────────────────────
  static const Color amberPrimary = Color(0xFFF59E0B);
  static const Color amberPrimarySoft = Color(0xFFFBBF24);
  static const Color amberGradA = Color(0xFFF59E0B);
  static const Color amberGradB = Color(0xFFD97706);
  static const Color amberWarning = Color(0xFFFB923C);
  static const Color amberBgBase = Color(0xFF15120A);
  static const Color amberBgDeep = Color(0xFF100D08);
  static const Color amberBgElevated = Color(0xFF2A2413);
  static const Color amberLightBg = Color(0xFFFAF6EE);
  static const Color amberLightBgDeep = Color(0xFFF1E9DA);

  // ── Accent-aware getters ──────────────────────────────────────────────────
  static Color get primary =>
      accent == accentAmber ? amberPrimary : emeraldPrimary;
  static Color get primarySoft =>
      accent == accentAmber ? amberPrimarySoft : emeraldPrimarySoft;
  static Color get gradA => accent == accentAmber ? amberGradA : emeraldGradA;
  static Color get gradB => accent == accentAmber ? amberGradB : emeraldGradB;
  static Color get warning =>
      accent == accentAmber ? amberWarning : emeraldWarning;
  static Color get bgBase =>
      accent == accentAmber ? amberBgBase : emeraldBgBase;
  static Color get bgDeep =>
      accent == accentAmber ? amberBgDeep : emeraldBgDeep;
  static Color get bgElevated =>
      accent == accentAmber ? amberBgElevated : emeraldBgElevated;
  static Color get lightBg =>
      accent == accentAmber ? amberLightBg : emeraldLightBg;
  static Color get lightBgDeep =>
      accent == accentAmber ? amberLightBgDeep : emeraldLightBgDeep;

  // ── Neutral (shared by both accents) ──────────────────────────────────────
  static const Color danger = Color(0xFFF43F5E);
  static const Color info = Color(0xFF38BDF8);
  static const Color indigo = Color(0xFF818CF8);

  // ── Text (dark) ───────────────────────────────────────────────────────────
  static const Color _textPrimaryDark = Color(0xFFF1F5F9);
  static const Color _textSecondaryDark = Color(0xFF94A3B8);
  static const Color _textMutedDark = Color(0xFF64748B);

  // ── Text (light) ──────────────────────────────────────────────────────────
  static const Color lightText = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF64748B);

  // ── Glass surfaces (dark) ────────────────────────────────────────────────
  static const Color _glassFillDark = Color(0x14FFFFFF);
  static const Color _glassFillStrongDark = Color(0x1FFFFFFF);
  static const Color _glassBorderDark = Color(0x22FFFFFF);
  static const Color _glassShadowDark = Color(0x66000000);

  // ── Glass surfaces (light) ───────────────────────────────────────────────
  static const Color lightGlassFill = Color(0x99FFFFFF);
  static const Color lightGlassFillStrong = Color(0xD9FFFFFF);
  static const Color lightGlassBorder = Color(0x1F0F172A);
  static const Color lightGlassShadow = Color(0x120F172A);

  // ── Theme-aware getters ───────────────────────────────────────────────────

  /// Main text color — near-white on dark, slate-900 on light.
  static Color get textPrimary => _isDark ? _textPrimaryDark : lightText;

  /// Secondary text color — slate-400 on dark, slate-600 on light.
  static Color get textSecondary =>
      _isDark ? _textSecondaryDark : lightTextSecondary;

  /// Muted text / icon color — slate-500 with the right luminance per theme.
  static Color get textMuted => _isDark ? _textMutedDark : lightTextMuted;

  /// Subtle translucent fill (cards, chips, steppers).
  static Color get glassFill => _isDark ? _glassFillDark : lightGlassFill;

  /// Stronger translucent fill (nav bar, switchers).
  static Color get glassFillStrong =>
      _isDark ? _glassFillStrongDark : lightGlassFillStrong;

  /// Hairline border color.
  static Color get glassBorder => _isDark ? _glassBorderDark : lightGlassBorder;

  /// Card shadow color — deep on dark, soft on light.
  static Color get glassShadow => _isDark ? _glassShadowDark : lightGlassShadow;
}
