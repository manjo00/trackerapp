import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Wraps [FlutterLocalNotificationsPlugin] with everything the app needs.
///
/// ## Concept: local notifications
/// A "local" notification lives entirely on the device — no server or internet
/// needed. We tell the OS "fire this notification at 9 AM every day" and
/// Android handles it even when the app is closed.
///
/// ## Concept: timezones
/// [zonedSchedule] requires a [tz.TZDateTime] (timezone-aware DateTime).
/// We call [tz.initializeTimeZones()] once at startup and then always use
/// [tz.local] so the alarm fires at the right local time, not UTC.
///
/// ## Notification IDs
/// Each scheduled notification gets a unique integer ID.
/// Using the same ID to re-schedule silently replaces the old alarm.
///   0 — daily habit + task reminder
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 0;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'life_tracker_reminders',       // channel id — must match below
    'Daily Reminders',              // shown in Android system settings
    description: 'Daily habit and task reminder',
    importance: Importance.defaultImportance,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Must be called once in [main] before [runApp].
  ///
  /// - Loads the timezone database (needed for [zonedSchedule]).
  /// - Configures the Android notification channel.
  /// - Requests the POST_NOTIFICATIONS permission on Android 13+.
  Future<void> init() async {
    // Load all timezone data into memory.
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
    );

    // Create the Android channel (harmless no-op if it already exists).
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Request the POST_NOTIFICATIONS runtime permission (Android 13+).
    // Returns true if granted, false if denied — we don't gate any feature
    // on this; the setting just becomes inert if the user says no.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── Schedule ──────────────────────────────────────────────────────────────

  /// Schedules (or replaces) the daily reminder to fire at [time] every day.
  ///
  /// [matchDateTimeComponents: DateTimeComponents.time] is the key flag:
  /// it makes the alarm repeat daily at the same hour/minute automatically —
  /// no workmanager or background tasks needed.
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await _plugin.zonedSchedule(
      _dailyReminderId,
      'Life Tracker',
      'Time to check your habits and tasks for today 🎯',
      _nextInstanceOf(time),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // iOS: treat the scheduled time as wall-clock time in the local timezone.
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancels the daily reminder (called when the user disables notifications).
  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyReminderId);
  }

  /// Cancels every scheduled notification — used for cleanup.
  Future<void> cancelAll() => _plugin.cancelAll();

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns a [tz.TZDateTime] for the next occurrence of [time].
  ///
  /// If [time] has already passed today, returns tomorrow's instance so the
  /// first alarm doesn't fire in the past (which would trigger immediately).
  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
