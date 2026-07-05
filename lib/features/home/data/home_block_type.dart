import 'package:flutter/material.dart';

/// The kinds of block the Home dashboard can show.
///
/// The user's layout is an ordered list of these, stored in preferences
/// by name (see SettingsNotifier). A type absent from the list is simply
/// not shown; the Edit Home screen offers it under "Add block".
enum HomeBlockType {
  urgent,
  dueToday,
  captured,
  thisWeek,
  workout;

  String get label => switch (this) {
        urgent => 'Urgent',
        dueToday => 'Due today',
        captured => 'Captured',
        thisWeek => 'This week',
        workout => 'Workout',
      };

  IconData get icon => switch (this) {
        urgent => Icons.local_fire_department_rounded,
        dueToday => Icons.today_rounded,
        captured => Icons.inbox_rounded,
        thisWeek => Icons.view_week_rounded,
        workout => Icons.fitness_center_rounded,
      };

  /// Shipped layout — slice-1 order with the workout block appended, so
  /// existing users see what they had plus the new block at the bottom.
  static const List<HomeBlockType> defaults = [
    urgent,
    dueToday,
    captured,
    thisWeek,
    workout,
  ];

  /// Parses a stored layout. Unknown names are dropped and duplicates
  /// collapse to their first occurrence. A null [raw] (nothing stored yet)
  /// yields [defaults]; an explicit empty list stays empty — the user
  /// removed every block on purpose.
  static List<HomeBlockType> parse(List<String>? raw) {
    if (raw == null) return defaults;
    final List<HomeBlockType> result = [];
    for (final String name in raw) {
      final HomeBlockType? type =
          values.where((t) => t.name == name).firstOrNull;
      if (type != null && !result.contains(type)) result.add(type);
    }
    return result;
  }
}
