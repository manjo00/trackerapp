import 'package:flutter/material.dart';

/// Every tab in the bottom navigation bar.
///
/// The [index] of each value matches the branch index in [StatefulShellRoute],
/// so [AppTab.today.index] == 0, [AppTab.habits.index] == 1, etc.
enum AppTab {
  today,
  habits,
  tasks,
  planner;

  String get label => switch (this) {
        today => 'Today',
        habits => 'Habits',
        tasks => 'Tasks',
        planner => 'Planner',
      };

  IconData get icon => switch (this) {
        today => Icons.wb_sunny_outlined,
        habits => Icons.radio_button_unchecked_rounded,
        tasks => Icons.check_box_outline_blank_rounded,
        planner => Icons.calendar_today_rounded,
      };

  IconData get selectedIcon => switch (this) {
        today => Icons.wb_sunny_rounded,
        habits => Icons.task_alt_rounded,
        tasks => Icons.check_box_rounded,
        planner => Icons.calendar_month_rounded,
      };
}

/// Immutable snapshot of all user preferences.
///
/// Stored in [SharedPreferences] by [SettingsNotifier].
/// Read anywhere via `ref.watch(settingsProvider)`.
class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.visibleTabs,
  });

  final ThemeMode themeMode;

  /// The set of tabs the user has chosen to show.
  /// Always contains at least one element.
  final Set<AppTab> visibleTabs;

  /// Shipped defaults — all tabs on, follow system theme.
  static const AppSettings defaults = AppSettings(
    themeMode: ThemeMode.system,
    visibleTabs: {
      AppTab.today,
      AppTab.habits,
      AppTab.tasks,
      AppTab.planner,
    },
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    Set<AppTab>? visibleTabs,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        visibleTabs: visibleTabs ?? this.visibleTabs,
      );
}
