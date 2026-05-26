import 'package:flutter/material.dart';

/// Named colour constants for the life_tracker palette.
///
/// Using named constants means we never scatter raw hex values across widgets.
/// If the brand colour ever changes, we update it here and it propagates
/// everywhere automatically.
abstract final class AppColors {
  // ── Seed colour ──────────────────────────────────────────────────────────
  /// The single "seed" colour Flutter uses to derive the full Material 3
  /// palette.  Changing this one value reshapes the entire colour scheme.
  static const Color seed = Color(0xFF7C6FE0); // muted indigo / blurple

  // ── Dark surface stack (Discord-warm, not cold blue-grey) ────────────────
  /// Page/scaffold background — the darkest layer.
  static const Color darkBackground = Color(0xFF1C1A1E);

  /// Card / list-item surface — sits one step above the background.
  static const Color darkSurface = Color(0xFF2B2830);

  /// Elevated input fields, modals — one more step up.
  static const Color darkElevated = Color(0xFF353240);

  // ── Light surface stack (warm cream, not stark white) ────────────────────
  static const Color lightBackground = Color(0xFFFFFBF5);
  static const Color lightSurface = Color(0xFFF2EDE8);

  // ── Streak / gamification ────────────────────────────────────────────────
  /// Colour used behind the streak badge (warm amber — feels earned).
  static const Color streakAmber = Color(0xFFFFB347);
}
