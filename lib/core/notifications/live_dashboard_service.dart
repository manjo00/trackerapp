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

  /// Slideshow payload the native service pages through.
  static const String _cardsKey = 'live_cards';

  /// Snoozed card ids ("task:12" → hide-until epoch ms). Written by the
  /// notification's snooze action (phase 3); filtered here on every sync.
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

  /// Task priority (0 low / 1 med / 2 high) → accent hex (matches the
  /// home-screen widget's priority dots).
  static String _priorityHex(int p) => switch (p) {
        2 => '#FFE07070', // high — soft red
        0 => '#FF8E9AAF', // low — muted slate
        _ => '#FFFFB347', // medium — warm amber
      };

  static const String _habitHex = '#FFA6ABEC'; // periwinkle
  static const String _inboxHex = '#FF8E9AAF'; // slate

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Rebuilds the slideshow payload from the database and hands it to the
  /// native service. Cheap one-shot queries — called from the same
  /// launch/resume/background hooks as the home-screen widget sync.
  static Future<void> syncCards(AppDatabase db) async {
    try {
      final DateTime now = DateTime.now();
      final String today = _dateKey(DateTime(now.year, now.month, now.day));

      // Live snoozes: drop expired entries, keep active ones for filtering.
      final Map<String, dynamic> snoozes = _decodeMap(
          await HomeWidget.getWidgetData<String>(_snoozesKey));
      snoozes.removeWhere((_, until) =>
          until is! num || until <= now.millisecondsSinceEpoch);

      final List<Map<String, dynamic>> cards = [];

      // ── Tasks: overdue first, then due today, then inbox (undated) ──────
      final tasks = await TasksDao(db).getAllTasks();
      final pending = tasks.where((t) => !t.isCompleted).toList();

      final overdue = pending
          .where((t) => t.dueDate != null && (t.dueDate as String) != today)
          .where((t) => (t.dueDate as String).compareTo(today) < 0)
          .toList()
        ..sort((a, b) =>
            (a.dueDate as String).compareTo(b.dueDate as String));
      for (final t in overdue) {
        final int days = DateTime.parse(today)
            .difference(DateTime.parse(t.dueDate as String))
            .inDays;
        cards.add({
          'type': 'task',
          'id': t.id,
          'title': t.title,
          'sub': '${days}d overdue',
          'color': '#FFE57373', // overdue red beats priority colour
        });
      }

      final dueToday = pending.where((t) => t.dueDate == today).toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));
      for (final t in dueToday) {
        final String time =
            t.dueTime == null ? '' : ' · ${t.dueTime as String}';
        cards.add({
          'type': 'task',
          'id': t.id,
          'title': t.title,
          'sub': 'Due today$time',
          'color': _priorityHex(t.priority),
        });
      }

      // ── Habits not yet checked off today ────────────────────────────────
      final HabitsDao habitsDao = HabitsDao(db);
      for (final h in await habitsDao.getAllHabits()) {
        if (await habitsDao.isCompletedOn(h.id, today)) continue;
        cards.add({
          'type': 'habit',
          'id': h.id,
          'title': h.name,
          'sub': 'Habit',
          'color': _habitHex,
        });
      }

      // ── Inbox: undated captures ──────────────────────────────────────────
      final inbox = pending.where((t) => t.dueDate == null).toList()
        ..sort((a, b) => b.priority.compareTo(a.priority));
      for (final t in inbox) {
        cards.add({
          'type': 'inbox',
          'id': t.id,
          'title': t.title,
          'sub': 'Inbox',
          'color': _inboxHex,
        });
      }

      // Hide snoozed cards.
      cards.removeWhere((c) => snoozes.containsKey('${c['type']}:${c['id']}'));

      await HomeWidget.saveWidgetData<String>(
          _snoozesKey, jsonEncode(snoozes));
      await HomeWidget.saveWidgetData<String>(_cardsKey, jsonEncode(cards));

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
