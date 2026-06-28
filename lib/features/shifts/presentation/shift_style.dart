import 'package:flutter/material.dart';
import '../data/models/work_shift_model.dart';

/// The single source of truth for how each shift type looks.
///
/// Every calendar surface (Planner cells, the date-picker, Today tiles) reads
/// colors and icons from here, so the schedule looks identical everywhere and
/// re-theming is a one-line change.
///
/// The fills are intentionally light, desaturated tints with dark foregrounds,
/// so the day number stays readable. They render as bright cells in dark mode,
/// which is the desired "shift days pop" effect.
class ShiftStyle {
  const ShiftStyle._();

  // ── Day shift — desaturated cyan-blue ──────────────────────────────────────
  static const Color dayFill = Color(0xFFDEEDEF);
  static const Color dayForeground = Color(0xFF0F5B6B);
  static const Color dayIconColor = Color(0xFF1A7E91);

  // ── Night shift — deeper, muted navy-purple ────────────────────────────────
  static const Color nightFill = Color(0xFFD7DBEC);
  static const Color nightForeground = Color(0xFF2E3270);
  static const Color nightIconColor = Color(0xFF3A3E86);

  /// Background tint for a day cell / tile of [type].
  static Color fill(ShiftType type) => switch (type) {
        ShiftType.day => dayFill,
        ShiftType.night => nightFill,
      };

  /// Text colour (day number, labels) for [type] — high contrast on [fill].
  static Color foreground(ShiftType type) => switch (type) {
        ShiftType.day => dayForeground,
        ShiftType.night => nightForeground,
      };

  /// Slightly brighter colour for the leading icon.
  static Color iconColor(ShiftType type) => switch (type) {
        ShiftType.day => dayIconColor,
        ShiftType.night => nightIconColor,
      };

  /// Sun for day, moon for night.
  static IconData icon(ShiftType type) => switch (type) {
        ShiftType.day => Icons.light_mode_rounded,
        ShiftType.night => Icons.dark_mode_rounded,
      };
}
