import 'package:flutter/material.dart';

import '../constants/app_strings.dart';

/// Every tab in the bottom navigation bar.
///
/// The [index] of each value matches the branch index in [StatefulShellRoute],
/// so [AppTab.today.index] == 0, [AppTab.home.index] == 1, etc.
enum AppTab {
  today,
  home,     // dashboard landing view (replaced Inbox in settings v3)
  habits,
  lists,    // task lists overview (replaced flat Tasks in settings v3)
  planner,
  trackers,
  workout;

  String get label => switch (this) {
        today => 'Today',
        home => 'Home',
        habits => 'Habits',
        lists => kListNounPlural,
        planner => 'Planner',
        trackers => 'Trackers',
        workout => 'Workout',
      };

  IconData get icon => switch (this) {
        today => Icons.wb_sunny_outlined,
        home => Icons.home_outlined,
        habits => Icons.radio_button_unchecked_rounded,
        lists => Icons.folder_copy_outlined,
        planner => Icons.calendar_today_rounded,
        trackers => Icons.bar_chart_outlined,
        workout => Icons.fitness_center_outlined,
      };

  IconData get selectedIcon => switch (this) {
        today => Icons.wb_sunny_rounded,
        home => Icons.home_rounded,
        habits => Icons.task_alt_rounded,
        lists => Icons.folder_copy_rounded,
        planner => Icons.calendar_month_rounded,
        trackers => Icons.bar_chart_rounded,
        workout => Icons.fitness_center_rounded,
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
    required this.notificationsEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.experimentalTargets,
    this.devMode = false,
  });

  final ThemeMode themeMode;

  /// The set of tabs the user has chosen to show.
  /// Always contains at least one element.
  final Set<AppTab> visibleTabs;

  /// Whether the daily reminder notification is scheduled.
  final bool notificationsEnabled;

  /// Hour component of the daily reminder time (0–23).
  final int reminderHour;

  /// Minute component of the daily reminder time (0–59).
  final int reminderMinute;

  /// Labs: reveals the experimental weekly muscle-target workout mode
  /// (the Targets ⇄ Program switch). Off by default — the Workout tab
  /// shows the classic program view until the user opts in.
  final bool experimentalTargets;

  /// Developer mode — unlocked by tapping the drawer's About tile 7×.
  /// Reveals dev-only tooling (GitHub feedback sync) that shouldn't be
  /// visible in the build friends install; off by default.
  final bool devMode;

  /// Convenience getter — the reminder as a Flutter [TimeOfDay].
  TimeOfDay get reminderTime => TimeOfDay(hour: reminderHour, minute: reminderMinute);

  /// Shipped defaults — Home + Lists + Planner in the bottom nav;
  /// Today / Habits / Trackers / Workout accessible from the drawer.
  static const AppSettings defaults = AppSettings(
    themeMode: ThemeMode.system,
    visibleTabs: {
      AppTab.home,
      AppTab.lists,
      AppTab.planner,
    },
    notificationsEnabled: false,
    reminderHour: 9,
    reminderMinute: 0,
    experimentalTargets: false,
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    Set<AppTab>? visibleTabs,
    bool? notificationsEnabled,
    int? reminderHour,
    int? reminderMinute,
    bool? experimentalTargets,
    bool? devMode,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        visibleTabs: visibleTabs ?? this.visibleTabs,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
        experimentalTargets: experimentalTargets ?? this.experimentalTargets,
        devMode: devMode ?? this.devMode,
      );
}
