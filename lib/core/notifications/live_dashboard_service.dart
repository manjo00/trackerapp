import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../../features/habits/data/dao/habits_dao.dart';
import '../../features/tasks/data/dao/tasks_dao.dart';
import '../database/app_database.dart';

/// Flutter-side remote control for the persistent "Live dashboard"
/// notification (native LiveDashboardService.kt).
///
/// The native side owns the notification; this class only (a) commands it
/// over the `uplan/live` MethodChannel, (b) stores the user's on/off
/// preference, and (c) pre-renders the slideshow cards as JSON into the
/// store the native side reads (HomeWidgetPreferences, via home_widget).
class LiveDashboardService {
  const LiveDashboardService._();

  static const MethodChannel _channel = MethodChannel('uplan/live');

  /// Prefs key — read by the settings screen and the launch/resume hooks.
  static const String _enabledKey = 'live_enabled';

  /// Slideshow payload: every pending task and habit as raw data, each with
  /// its own date. The native service buckets, words and colours them as it
  /// draws (see LiveCards.kt), so the notification stays right on a day the
  /// app never ran.
  static const String _itemsKey = 'live_items';

  /// Habit ids already ticked on [_snapshotDateKey]. Paired with that date so
  /// the native side can tell "ticked today" from "ticked on an older day",
  /// where the honest answer is that nothing has been ticked yet.
  static const String _habitsDoneKey = 'live_habits_done';

  /// The day [_itemsKey] describes ("yyyy-MM-dd").
  static const String _snapshotDateKey = 'live_snapshot_date';

  /// Snoozed card ids ("task:12" → hide-until epoch ms). Written by the
  /// notification's snooze action; expired entries are pruned here, and
  /// whether a live one still hides its card is judged natively.
  static const String _snoozesKey = 'live_snoozes';

  /// Whether the user has turned the live notification on.
  static Future<bool> isEnabled() async =>
      await HomeWidget.getWidgetData<bool>(_enabledKey) ?? false;

  /// Persists the toggle and starts/stops the native service to match.
  static Future<void> setEnabled(bool enabled) async {
    await HomeWidget.saveWidgetData<bool>(_enabledKey, enabled);
    if (enabled) {
      await start();
    } else {
      await stop();
    }
  }

  /// Starts (or re-shows) the dashboard notification.
  static Future<void> start() => _invoke('startDashboard');

  /// Removes the dashboard notification and stops the service.
  static Future<void> stop() => _invoke('stopDashboard');

  /// Asks the service to re-read prefs and re-render the card.
  static Future<void> refresh() => _invoke('refreshDashboard');

  /// Convenience for launch/resume hooks: start only if the user opted in.
  static Future<void> startIfEnabled() async {
    if (await isEnabled()) await start();
  }

  // ── Rest-timer Live Update (Now Bar) ─────────────────────────────────────
  //
  // A second, transient notification (id 50002) that Android 16 promotes to
  // the status-bar chip / Samsung Now Bar / Flip cover screen. Posted
  // regardless of the dashboard toggle — it belongs to the workout, not the
  // dashboard.

  /// Posts (or re-posts after ±15s) the rest countdown.
  static Future<void> startRest({
    required int remainingSeconds,
    required int totalSeconds,
  }) async {
    try {
      await _channel.invokeMethod<void>('startRest', {
        'endAtMillis': DateTime.now()
                .add(Duration(seconds: remainingSeconds))
                .millisecondsSinceEpoch,
        'totalSeconds': totalSeconds,
      });
    } on MissingPluginException {
      // Non-Android platform / tests.
    } on PlatformException {
      // Never let a notification failure break the timer.
    }
  }

  /// Removes the rest countdown (skipped, finished, or workout over).
  static Future<void> cancelRest() => _invoke('cancelRest');

  /// Whether the OS lets us promote the rest timer to a Live Update
  /// (Samsung Now Bar / status chip). False when the "Live updates"
  /// permission hasn't been granted to the app (or below Android 16).
  static Future<bool> canPromote() async {
    try {
      return await _channel.invokeMethod<bool>('canPromote') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  // ── Slideshow cards ──────────────────────────────────────────────────────

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Rebuilds the slideshow payload from the database and hands it to the
  /// native service. Cheap one-shot queries — called from the same
  /// launch/resume/background hooks as the home-screen widget sync.
  ///
  /// What goes across is deliberately RAW: every pending task and habit with
  /// its own date, and nothing phrased relative to today. The native side
  /// decides which bucket each one falls in (overdue / due today / habit /
  /// captured), what it says and what colour it is, at the moment it draws.
  ///
  /// That matters because this notification can sit on screen for days. When
  /// the wording *and the bucketing* were baked here, a task became overdue
  /// overnight and the card went on saying "Due today" — or stayed in Captured
  /// — until the app happened to run again.
  static Future<void> syncCards(AppDatabase db) async {
    try {
      final DateTime now = DateTime.now();
      final String today = _dateKey(DateTime(now.year, now.month, now.day));

      // Live snoozes: drop entries that have already expired. Which of the
      // survivors are still hiding a card is judged natively, against the
      // clock, so a snooze running out brings its card back on its own.
      final Map<String, dynamic> snoozes = _decodeMap(
          await HomeWidget.getWidgetData<String>(_snoozesKey));
      snoozes.removeWhere((_, until) =>
          until is! num || until <= now.millisecondsSinceEpoch);

      final List<Map<String, dynamic>> items = [];

      // Every pending task, with its date rather than a verdict about it.
      final tasks = await TasksDao(db).getAllTasks();
      for (final t in tasks.where((t) => !t.isCompleted)) {
        items.add({
          'type': 'task',
          'id': t.id,
          'title': t.title,
          'date': t.dueDate,
          'time': t.dueTime,
          'prio': t.priority,
          // Captured means "filed nowhere" — listId NULL, no row for it.
          'listed': t.listId != null,
        });
      }

      // Every active habit. Which ones are already ticked is a fact about
      // *today*, so it travels separately, stamped with the day it describes:
      // on any later day nothing has been ticked yet and they all come back.
      final HabitsDao habitsDao = HabitsDao(db);
      final List<int> doneToday = [];
      for (final h in await habitsDao.getAllHabits()) {
        items.add({'type': 'habit', 'id': h.id, 'title': h.name});
        if (await habitsDao.isCompletedOn(h.id, today)) doneToday.add(h.id);
      }

      await HomeWidget.saveWidgetData<String>(
          _snoozesKey, jsonEncode(snoozes));
      await HomeWidget.saveWidgetData<String>(_itemsKey, jsonEncode(items));
      await HomeWidget.saveWidgetData<String>(
          _habitsDoneKey, jsonEncode(doneToday));
      await HomeWidget.saveWidgetData<String>(_snapshotDateKey, today);

      // Re-render only if the dashboard is on — refresh() would otherwise
      // start the service for a user who turned it off.
      await startIfEnabled();
    } catch (_) {
      // The dashboard must never break app flows (saves, navigation, ...).
    }
  }

  static Map<String, dynamic> _decodeMap(String? json) {
    if (json == null || json.isEmpty) return {};
    try {
      final decoded = jsonDecode(json);
      return decoded is Map<String, dynamic> ? decoded : {};
    } on FormatException {
      return {};
    }
  }

  static Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      // Non-Android platform or channel not registered (e.g. tests) — the
      // dashboard simply doesn't exist there.
    } on PlatformException {
      // Native failure shouldn't break app flows (saves, navigation, ...).
    }
  }
}
