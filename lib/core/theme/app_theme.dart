import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Provides the two [ThemeData] objects the app switches between.
///
/// Both themes use Material 3 (`useMaterial3: true`) and are derived from the
/// same [AppColors.seed] colour via [ColorScheme.fromSeed].  Flutter generates
/// a full, harmonious palette from that single seed — we then override a few
/// surface colours to match our warm-dark / warm-light aesthetic.
abstract final class AppTheme {
  // ── Dark theme ────────────────────────────────────────────────────────────
  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    ).copyWith(
      // Replace Flutter's default cold-grey surfaces with our warm charcoal.
      surface: AppColors.darkBackground,
      surfaceContainerLowest: AppColors.darkBackground,
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainer: AppColors.darkSurface,
      surfaceContainerHigh: AppColors.darkElevated,
      surfaceContainerHighest: AppColors.darkElevated,
    );

    return _base(scheme);
  }

  // ── Light theme ───────────────────────────────────────────────────────────
  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
    ).copyWith(
      surface: AppColors.lightBackground,
      surfaceContainerLowest: AppColors.lightBackground,
      surfaceContainerLow: AppColors.lightSurface,
      surfaceContainer: AppColors.lightSurface,
    );

    return _base(scheme);
  }

  // ── Shared base ───────────────────────────────────────────────────────────
  /// Applies settings that are identical for both themes.
  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,

      // Cards sit one step above the background — use our warm-surface colour.
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0, // flat cards; depth comes from colour contrast, not shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // Bottom navigation bar matches the card surface, not the background.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primary.withAlpha(40),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // App bar is transparent so it blends with the background.
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),

      // FAB uses the accent colour so it pops against the dark background.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Input fields (used in AddHabitScreen) get a filled style.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
