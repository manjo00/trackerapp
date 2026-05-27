import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Wraps [FlutterLocalNotificationsPlugin] with everything the app needs.
///
/// ## How daily notifications work
/// [zonedSchedule] + [DateTimeComponents.time] tells the OS: "fire this
/// notification at HH:mm every day." The OS handles repeating — no background
/// service needed.
///
/// ## Why we use inexact scheduling
/// Android 12+ (API 31+) requires an extra system-settings permission for
/// *exact* alarms ([SCHEDULE_EXACT_ALARM]). Without it, exact alarms silently
/// fail. Inexact alarms need no extra permission and fire within a few minutes
/// of the target time — perfectly fine for a daily habit reminder.
///
/// ## Timezone fix
/// [tz.local] defaults to UTC until we explicitly set it. We use
/// [FlutterTimezone.getLocalTimezone()] to get the device's IANA name
/// (e.g. "Asia/Riyadh") and pass it to [tz.setLocalLocation], so "9 AM"
/// means 9 AM in the user's actual timezone.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 0;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'life_tracker_reminders',
    'Daily Reminders',
    description: 'Daily habit and task reminder',
    importance: Importance.defaultImportance,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Must be called once in [main] before [runApp].
  Future<void> init() async {
    // 1. Load all timezone definitions.
    tz.initializeTimeZones();

    // 2. Detect the device's local timezone (e.g. "Asia/Riyadh") and apply it
    //    so that tz.local matches the user's clock, not UTC.
    final String localTzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTzName));

    // 3. Configure the plugin.
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
    );

    // 4. Create the Android notification channel (no-op if it already exists).
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 5. Request POST_NOTIFICATIONS permission (Android 13+; ignored below).
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── Schedule ──────────────────────────────────────────────────────────────

  /// Schedules (or replaces) the daily reminder at [time] every day.
  /// Returns false if scheduling failed (e.g. permission denied) so the
  /// caller can react without crashing.
  Future<bool> scheduleDailyReminder(TimeOfDay time) async {
    try {
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
        // inexactAllowWhileIdle: fires within a few minutes of the target
        // time. No extra system permission needed.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        // Repeat daily at the same hour and minute.
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cancels the daily reminder.
  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyReminderId);
  }

  /// Cancels every scheduled notification.
  Future<void> cancelAll() => _plugin.cancelAll();

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns a [tz.TZDateTime] for the next occurrence of [time].
  /// If the time has already passed today, schedules for tomorrow.
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
