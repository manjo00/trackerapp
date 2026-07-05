import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notifications/notification_service.dart';
import 'app_settings.dart';

// ── SharedPreferences provider ────────────────────────────────────────────────

/// Holds the [SharedPreferences] singleton.
///
/// This provider is intentionally unimplemented here — it MUST be overridden
/// in [main()] after `SharedPreferences.getInstance()` resolves:
///
/// ```dart
/// ProviderScope(
///   overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
///   child: const LifeTrackerApp(),
/// )
/// ```
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);

// ── Settings StateNotifier ────────────────────────────────────────────────────

/// Manages [AppSettings] state and persists every change to [SharedPreferences].
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._prefs) : super(AppSettings.defaults) {
    _load();
  }

  final SharedPreferences _prefs;

  static const String _kTheme = 'theme_mode';
  static const String _kTabs = 'visible_tabs';
  static const String _kNotifications = 'notifications_enabled';
  static const String _kReminderHour = 'reminder_hour';
  static const String _kReminderMinute = 'reminder_minute';
  static const String _kExperimentalTargets = 'experimental_targets';
  static const String _kDevMode = 'dev_mode';
  static const String _kWeekStartsSunday = 'week_starts_sunday';

  // Settings schema version — increment when defaults need to be reset.
  static const int _currentSettingsVersion = 3;
  static const String _kSettingsVersion = 'settings_version';

  // ── Load ───────────────────────────────────────────────────────────────

  void _load() {
    // Migrate settings when upgrading to a new schema version.
    // Each block handles one version bump so users can skip versions.
    final int savedVersion = _prefs.getInt(_kSettingsVersion) ?? 1;
    if (savedVersion < 2) {
      // v2: Reset tabs to the then-new 3-tab default (Today + Inbox + Planner).
      // Old stored tabs used the 6-tab layout; clear to pick up new defaults.
      _prefs.remove(_kTabs);
    }
    if (savedVersion < 3) {
      // v3: the inbox tab became Home; the tasks tab became Lists.
      final List<String>? raw = _prefs.getStringList(_kTabs);
      if (raw != null) {
        final List<String> mapped = raw
            .map((s) => switch (s) { 'inbox' => 'home', 'tasks' => 'lists', _ => s })
            .toList();
        // The old default trio would map to {today,home,planner}: upgrade it
        // to the new default so the Lists tab is discoverable.
        final Set<String> set = mapped.toSet();
        if (set.length == 3 && set.containsAll({'today', 'home', 'planner'})) {
          _prefs.setStringList(_kTabs, ['home', 'lists', 'planner']);
        } else {
          _prefs.setStringList(_kTabs, mapped);
        }
      }
    }
    if (savedVersion < _currentSettingsVersion) {
      _prefs.setInt(_kSettingsVersion, _currentSettingsVersion);
    }

    state = AppSettings(
      themeMode: _loadTheme(),
      visibleTabs: _loadTabs(),
      notificationsEnabled:
          _prefs.getBool(_kNotifications) ?? AppSettings.defaults.notificationsEnabled,
      reminderHour:
          _prefs.getInt(_kReminderHour) ?? AppSettings.defaults.reminderHour,
      reminderMinute:
          _prefs.getInt(_kReminderMinute) ?? AppSettings.defaults.reminderMinute,
      experimentalTargets: _prefs.getBool(_kExperimentalTargets) ??
          AppSettings.defaults.experimentalTargets,
      devMode: _prefs.getBool(_kDevMode) ?? false,
      weekStartsSunday: _prefs.getBool(_kWeekStartsSunday) ?? false,
    );
  }

  ThemeMode _loadTheme() {
    final String? raw = _prefs.getString(_kTheme);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Set<AppTab> _loadTabs() {
    final List<String>? raw = _prefs.getStringList(_kTabs);
    if (raw == null || raw.isEmpty) return AppSettings.defaults.visibleTabs;

    final Set<AppTab> tabs = raw
        .map((s) => AppTab.values.where((t) => t.name == s).firstOrNull)
        .whereType<AppTab>()
        .toSet();

    return tabs.isEmpty ? AppSettings.defaults.visibleTabs : tabs;
  }

  // ── Write ──────────────────────────────────────────────────────────────

  /// Changes the app theme and persists the choice.
  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs.setString(_kTheme, mode.name);
  }

  /// Shows or hides [tab].
  /// Silently ignores requests to hide the last visible tab.
  void setTabVisible(AppTab tab, {required bool visible}) {
    final Set<AppTab> updated = Set<AppTab>.from(state.visibleTabs);

    if (visible) {
      updated.add(tab);
    } else {
      if (updated.length <= 1) return; // never remove the last tab
      updated.remove(tab);
    }

    state = state.copyWith(visibleTabs: updated);
    _prefs.setStringList(_kTabs, updated.map((t) => t.name).toList());
  }

  /// Enables or disables the daily reminder notification.
  ///
  /// When enabled: schedules the notification at [state.reminderTime].
  /// When disabled: cancels the scheduled notification.
  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _prefs.setBool(_kNotifications, enabled);

    if (enabled) {
      await NotificationService.instance
          .scheduleDailyReminder(state.reminderTime);
    } else {
      await NotificationService.instance.cancelDailyReminder();
    }
  }

  /// Toggles the experimental weekly muscle-target workout mode.
  void setExperimentalTargets(bool enabled) {
    state = state.copyWith(experimentalTargets: enabled);
    _prefs.setBool(_kExperimentalTargets, enabled);
  }

  /// Toggles developer mode (7 taps on the drawer's About tile).
  void setDevMode(bool enabled) {
    state = state.copyWith(devMode: enabled);
    _prefs.setBool(_kDevMode, enabled);
  }

  /// Switches the first day of the week (calendars + weekly stats).
  void setWeekStartsSunday(bool enabled) {
    state = state.copyWith(weekStartsSunday: enabled);
    _prefs.setBool(_kWeekStartsSunday, enabled);
  }

  /// Updates the reminder time and re-schedules if notifications are on.
  Future<void> setReminderTime(TimeOfDay time) async {
    state = state.copyWith(
      reminderHour: time.hour,
      reminderMinute: time.minute,
    );
    await _prefs.setInt(_kReminderHour, time.hour);
    await _prefs.setInt(_kReminderMinute, time.minute);

    // Only re-schedule if notifications are currently enabled.
    if (state.notificationsEnabled) {
      await NotificationService.instance.scheduleDailyReminder(time);
    }
  }
}

// ── Public provider ───────────────────────────────────────────────────────────

/// The single source of truth for all user preferences.
///
/// Usage (read):   `ref.watch(settingsProvider)`
/// Usage (write):  `ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.dark)`
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(ref.watch(sharedPreferencesProvider)),
);
