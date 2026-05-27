import 'package:flutter/material.dart';

/// Every tab in the bottom navigation bar.
///
/// The [index] of each value matches the branch index in [StatefulShellRoute],
/// so [AppTab.today.index] == 0, [AppTab.habits.index] == 1, etc.
enum AppTab {
  today,
  habits,
  tasks,
  planner,
  trackers;

  String get label => switch (this) {
        today => 'Today',
        habits => 'Habits',
        tasks => 'Tasks',
        planner => 'Planner',
        trackers => 'Trackers',
      };

  IconData get icon => switch (this) {
        today => Icons.wb_sunny_outlined,
        habits => Icons.radio_button_unchecked_rounded,
        tasks => Icons.check_box_outline_blank_rounded,
        planner => Icons.calendar_today_rounded,
        trackers => Icons.bar_chart_outlined,
      };

  IconData get selectedIcon => switch (this) {
        today => Icons.wb_sunny_rounded,
        habits => Icons.task_alt_rounded,
        tasks => Icons.check_box_rounded,
        planner => Icons.calendar_month_rounded,
        trackers => Icons.bar_chart_rounded,
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

  /// Convenience getter — the reminder as a Flutter [TimeOfDay].
  TimeOfDay get reminderTime => TimeOfDay(hour: reminderHour, minute: reminderMinute);

  /// Shipped defaults — all tabs on, system theme, 9 AM reminder (off).
  static const AppSettings defaults = AppSettings(
    themeMode: ThemeMode.system,
    visibleTabs: {
      AppTab.today,
      AppTab.habits,
      AppTab.tasks,
      AppTab.planner,
      AppTab.trackers,
    },
    notificationsEnabled: false,
    reminderHour: 9,
    reminderMinute: 0,
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    Set<AppTab>? visibleTabs,
    bool? notificationsEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        visibleTabs: visibleTabs ?? this.visibleTabs,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        reminderHour: reminderHour ?? this.reminderHour,
        reminderMinute: reminderMinute ?? this.reminderMinute,
      );
}
