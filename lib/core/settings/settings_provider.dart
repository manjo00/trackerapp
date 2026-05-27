import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // ── Load ───────────────────────────────────────────────────────────────

  void _load() {
    state = AppSettings(
      themeMode: _loadTheme(),
      visibleTabs: _loadTabs(),
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

    // Guard: always keep at least one tab.
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
