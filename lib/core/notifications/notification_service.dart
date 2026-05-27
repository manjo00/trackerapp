import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/habits/data/models/habit_model.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/trackers/data/models/tracker_model.dart';

/// Wraps [FlutterLocalNotificationsPlugin] with everything the app needs.
///
/// ## Notification ID ranges (never overlap these)
/// | Range              | Owner                                            |
/// |--------------------|--------------------------------------------------|
/// | 0                  | Global daily reminder                            |
/// | 1 – 9 999          | Habit reminders (one per habit, keyed by habitId)|
/// | 10 000 + id×3 + 0  | Task — 1 day before                              |
/// | 10 000 + id×3 + 1  | Task — 3 hours before                            |
/// | 10 000 + id×3 + 2  | Task — 5 minutes before                          |
/// | 30 000 + trackerId | Tracker daily reminders                          |
///
/// ## Timezone fix
/// `flutter_timezone` (the native plugin) is incompatible with Flutter 3's
/// embedding API, so we skip it. Instead we compute the UTC equivalent of
/// the target local time by reading `DateTime.now().timeZoneOffset`.
/// This is 100% portable and needs no native code.
///
/// ## Why inexact alarms
/// Android 12+ requires an explicit system-settings grant for exact alarms
/// (`SCHEDULE_EXACT_ALARM`). Without the grant, exact alarms fail silently.
/// Inexact alarms need no extra permission and fire within a few minutes —
/// perfectly adequate for reminders.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // ── Notification IDs ───────────────────────────────────────────────────────
  static const int _dailyReminderId = 0;
  static int _habitId(int habitId) => habitId;                      // 1–9999
  static int _taskId(int taskId, int slot) => 10000 + taskId * 3 + slot; // 0/1/2
  static int _trackerId(int trackerId) => 30000 + trackerId;

  // ── Channels ───────────────────────────────────────────────────────────────
  static const AndroidNotificationChannel _globalChannel =
      AndroidNotificationChannel(
    'life_tracker_reminders',
    'Daily Reminders',
    description: 'Daily habit and task check-in',
    importance: Importance.defaultImportance,
  );

  static const AndroidNotificationChannel _itemChannel =
      AndroidNotificationChannel(
    'life_tracker_item_reminders',
    'Item Reminders',
    description: 'Per-habit, per-task, and per-tracker reminders',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Must be called once in [main] before [runApp].
  Future<void> init() async {
    tz.initializeTimeZones();
    // No setLocalLocation needed — we schedule in UTC directly.

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
    );

    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(_globalChannel);
    await android?.createNotificationChannel(_itemChannel);
    await android?.requestNotificationsPermission();
  }

  // ── Global daily reminder ──────────────────────────────────────────────────

  /// Schedules (or replaces) the global daily reminder at [time] every day.
  Future<bool> scheduleDailyReminder(TimeOfDay time) async {
    try {
      await _plugin.zonedSchedule(
        _dailyReminderId,
        'Life Tracker',
        'Time to check your habits and tasks for today 🎯',
        _nextDailyUtc(time),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _globalChannel.id,
            _globalChannel.name,
            channelDescription: _globalChannel.description,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> cancelDailyReminder() => _plugin.cancel(_dailyReminderId);
  Future<void> cancelAll() => _plugin.cancelAll();

  // ── Per-habit reminders ────────────────────────────────────────────────────

  /// Schedules a daily reminder for [habit] at its stored [reminderTime].
  ///
  /// Does nothing if [habit.reminderEnabled] is false or [habit.reminderTime]
  /// is null.
  Future<bool> scheduleHabitReminder(HabitModel habit) async {
    if (!habit.reminderEnabled || habit.reminderTime == null) return false;
    final TimeOfDay? time = _parseTime(habit.reminderTime!);
    if (time == null) return false;
    return _scheduleDaily(
      id: _habitId(habit.id),
      title: habit.name,
      body: 'Don\'t forget to mark your habit today ✅',
      time: time,
    );
  }

  Future<void> cancelHabitReminder(int habitId) =>
      _plugin.cancel(_habitId(habitId));

  // ── Per-tracker reminders ─────────────────────────────────────────────────

  Future<bool> scheduleTrackerReminder(TrackerModel tracker) async {
    if (!tracker.reminderEnabled || tracker.reminderTime == null) return false;
    final TimeOfDay? time = _parseTime(tracker.reminderTime!);
    if (time == null) return false;
    return _scheduleDaily(
      id: _trackerId(tracker.id),
      title: '${tracker.icon} ${tracker.name}',
      body: 'Time to log your tracker 📋',
      time: time,
    );
  }

  Future<void> cancelTrackerReminder(int trackerId) =>
      _plugin.cancel(_trackerId(trackerId));

  // ── Per-task reminders ─────────────────────────────────────────────────────

  /// Schedules up to 3 one-shot notifications for [task] based on its
  /// [reminderLeadTimes].
  ///
  /// Does nothing if:
  ///   - [task.reminderEnabled] is false
  ///   - [task.dueDate] is null (no deadline to count back from)
  ///   - All computed fire times are already in the past
  Future<bool> scheduleTaskReminders(TaskModel task) async {
    await cancelTaskReminders(task.id); // clear stale slots first
    if (!task.reminderEnabled || task.dueDate == null) return false;

    final List<int> leadTimes = task.leadTimeMinutes;
    if (leadTimes.isEmpty) return false;

    // Parse due date + time.  Fall back to 09:00 when no dueTime is set.
    DateTime due;
    try {
      due = DateTime.parse(task.dueDate!);
    } catch (_) {
      return false;
    }

    final TimeOfDay dueTimeParsed =
        _parseTime(task.dueTime ?? '09:00') ?? const TimeOfDay(hour: 9, minute: 0);

    due = DateTime(
      due.year, due.month, due.day,
      dueTimeParsed.hour, dueTimeParsed.minute,
    );

    bool anyScheduled = false;
    for (int slot = 0; slot < leadTimes.length; slot++) {
      final DateTime fireTime =
          due.subtract(Duration(minutes: leadTimes[slot]));

      // Skip if already in the past.
      if (fireTime.isBefore(DateTime.now())) continue;

      final String leadLabel = _leadLabel(leadTimes[slot]);

      try {
        await _plugin.zonedSchedule(
          _taskId(task.id, slot),
          task.title,
          'Due $leadLabel ⏰',
          _toTzUtc(fireTime),
          NotificationDetails(
            android: AndroidNotificationDetails(
              _itemChannel.id,
              _itemChannel.name,
              channelDescription: _itemChannel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
          // One-shot — no matchDateTimeComponents.
        );
        anyScheduled = true;
      } catch (_) {
        // Skip this slot but continue with others.
      }
    }
    return anyScheduled;
  }

  /// Cancels all 3 notification slots for [taskId].
  Future<void> cancelTaskReminders(int taskId) async {
    for (int slot = 0; slot < 3; slot++) {
      await _plugin.cancel(_taskId(taskId, slot));
    }
  }

  // ── Reschedule on app start (handles OS reboot clearing notifications) ─────

  /// Re-schedules every currently-enabled reminder across habits, tasks, and
  /// trackers.  Called once in [main] after [init] and after the database is
  /// ready.  Cheap to run because it only writes notifications, not DB rows.
  Future<void> rescheduleAll({
    required List<HabitModel> habits,
    required List<TaskModel> tasks,
    required List<TrackerModel> trackers,
  }) async {
    for (final h in habits) {
      if (h.reminderEnabled) await scheduleHabitReminder(h);
    }
    for (final t in tasks) {
      if (t.reminderEnabled && !t.isCompleted) await scheduleTaskReminders(t);
    }
    for (final tr in trackers) {
      if (tr.reminderEnabled && !tr.isTemplate) {
        await scheduleTrackerReminder(tr);
      }
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Schedules a repeating daily notification.
  Future<bool> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        _nextDailyUtc(time),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _itemChannel.id,
            _itemChannel.name,
            channelDescription: _itemChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns the next UTC [tz.TZDateTime] at which local-time [time] occurs.
  ///
  /// We avoid `tz.local` (which defaults to UTC and requires a native plugin
  /// to detect correctly). Instead we compute: UTC_fire = local_time - offset.
  /// If the result is already in the past, add 24 hours.
  tz.TZDateTime _nextDailyUtc(TimeOfDay time) {
    final Duration offset = DateTime.now().timeZoneOffset;
    final tz.TZDateTime nowUtc = tz.TZDateTime.now(tz.UTC);

    // Local fire time expressed in UTC.
    int utcHour = time.hour - offset.inHours;
    int utcMinute = time.minute - offset.inMinutes.remainder(60);

    // Normalise minute overflow/underflow.
    if (utcMinute < 0) {
      utcMinute += 60;
      utcHour -= 1;
    } else if (utcMinute >= 60) {
      utcMinute -= 60;
      utcHour += 1;
    }
    // Normalise hour (0–23).
    utcHour = utcHour % 24;

    tz.TZDateTime target = tz.TZDateTime(
      tz.UTC,
      nowUtc.year, nowUtc.month, nowUtc.day,
      utcHour, utcMinute,
    );

    if (target.isBefore(nowUtc)) {
      target = target.add(const Duration(days: 1));
    }
    return target;
  }

  /// Converts a plain [DateTime] (local) to a UTC [tz.TZDateTime].
  tz.TZDateTime _toTzUtc(DateTime localDt) {
    final utcDt = localDt.toUtc();
    return tz.TZDateTime(
      tz.UTC,
      utcDt.year, utcDt.month, utcDt.day,
      utcDt.hour, utcDt.minute,
    );
  }

  /// Parses "HH:mm" → [TimeOfDay]. Returns null on parse error.
  TimeOfDay? _parseTime(String s) {
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Human-readable label for a lead time in minutes.
  String _leadLabel(int minutes) {
    if (minutes >= 1440) return 'in ${minutes ~/ 1440} day${minutes >= 2880 ? 's' : ''}';
    if (minutes >= 60) return 'in ${minutes ~/ 60} hour${minutes >= 120 ? 's' : ''}';
    return 'in $minutes minute${minutes != 1 ? 's' : ''}';
  }
}
