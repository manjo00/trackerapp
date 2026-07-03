import 'dart:convert';
import 'dart:typed_data' show Int64List;
import 'dart:ui' show DartPluginRegistrant;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/habits/data/models/habit_model.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/trackers/data/models/tracker_model.dart';

// ── Channel identifiers (shared by the app + the background alarm isolate) ────
const String kDailyChannelId = 'life_tracker_reminders';
const String kItemChannelId = 'life_tracker_item_reminders';
const String _kPrefPrefix = 'alarm_notif_'; // + alarm id → JSON payload

/// Runs in a BACKGROUND ISOLATE when an alarm fires (android_alarm_manager_plus).
///
/// flutter_local_notifications' own scheduling silently fails on One UI, but an
/// *immediate* `show()` always works — so we schedule a reliable alarm and post
/// the notification from here. The content was stashed in shared_preferences
/// under [_kPrefPrefix]+id when the alarm was scheduled.
@pragma('vm:entry-point')
Future<void> alarmNotificationCallback(int id) async {
  DartPluginRegistrant.ensureInitialized();

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final String? raw = prefs.getString('$_kPrefPrefix$id');
  if (raw == null) return;

  final Map<String, dynamic> data =
      jsonDecode(raw) as Map<String, dynamic>;
  final String channelId = (data['channel'] as String?) ?? kItemChannelId;
  final bool repeat = data['repeat'] == true;

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  await plugin.show(
    id,
    data['title'] as String? ?? 'Uplan',
    data['body'] as String? ?? '',
    NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelId == kDailyChannelId ? 'Daily Reminders' : 'Item Reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );

  // One-shot reminders clean up their stored payload; daily ones keep it.
  if (!repeat) await prefs.remove('$_kPrefPrefix$id');
}

/// Notification scheduling + display for the whole app.
///
/// - Immediate notifications (test, rest-timer) use flutter_local_notifications
///   directly — these work fine.
/// - Scheduled notifications use android_alarm_manager_plus to run
///   [alarmNotificationCallback] at the exact time, which then shows an
///   immediate notification. This sidesteps flutter_local_notifications'
///   scheduled-display failure on Samsung/One UI.
///
/// ## Notification / alarm ID ranges (never overlap)
/// | 0 | daily reminder · 1–9999 habits · 10000+id×3+slot tasks
/// | 30000+id trackers · 997 scheduled test · 998 rest · 999 immediate test
/// | 50001 live dashboard (FGS — LiveDashboardService.kt)
/// | 50002 rest-timer Live Update / Now Bar (RestLiveUpdate.kt)
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int _dailyReminderId = 0;
  static int _habitId(int habitId) => habitId;
  static int _taskId(int taskId, int slot) => 10000 + taskId * 3 + slot;
  static int _trackerId(int trackerId) => 30000 + trackerId;
  static const int _testId = 999;
  static const int _testScheduledId = 997;
  static const int _restCompleteId = 998;

  static const AndroidNotificationChannel _globalChannel =
      AndroidNotificationChannel(
    kDailyChannelId,
    'Daily Reminders',
    description: 'Daily habit and task check-in',
    importance: Importance.defaultImportance,
  );
  static const AndroidNotificationChannel _itemChannel =
      AndroidNotificationChannel(
    kItemChannelId,
    'Item Reminders',
    description: 'Per-habit, per-task, and per-tracker reminders',
    importance: Importance.high,
  );

  /// Rest-timer-finished gets its own channel because it must VIBRATE
  /// (gym: phone on the bench, screen off) and channel settings are
  /// immutable after creation — can't retrofit a pattern onto _itemChannel.
  static final AndroidNotificationChannel _restDoneChannel =
      AndroidNotificationChannel(
    'life_tracker_rest_done',
    'Rest finished',
    description: 'Buzz when the workout rest timer hits zero',
    importance: Importance.high,
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 400, 250, 400, 250, 600]),
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _canUseExact = false;
  bool get canUseExactAlarms => _canUseExact;

  // ── Init ────────────────────────────────────────────────────────────────────

  /// Call once in [main] before runApp. [AndroidAlarmManager.initialize] must
  /// also be called there (see main.dart).
  Future<void> init() async {
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
    await android?.createNotificationChannel(_restDoneChannel);

    final bool? granted = await android?.requestNotificationsPermission();
    _canUseExact = await android?.canScheduleExactNotifications() ?? false;
    debugPrint('[Notifications] init — notif:$granted exact:$_canUseExact');
  }

  // ── Immediate notifications (these already work) ─────────────────────────────

  Future<void> showTestNotification() => _showNow(
        _testId,
        'Uplan',
        'Notifications are working! 🎉',
      );

  /// Rest hit zero: notification + a strong buzz (its own channel — the
  /// in-app HapticFeedback only fires when the app is foregrounded).
  Future<void> showRestComplete() async {
    await _plugin.show(
      _restCompleteId,
      'Rest over 💪',
      'Time for your next set',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _restDoneChannel.id,
          _restDoneChannel.name,
          channelDescription: _restDoneChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
          vibrationPattern: _restDoneChannel.vibrationPattern,
          timeoutAfter: 10000,
        ),
      ),
    );
  }

  Future<void> _showNow(int id, String title, String body,
      {int? timeoutMs}) async {
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _itemChannel.id,
          _itemChannel.name,
          channelDescription: _itemChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          timeoutAfter: timeoutMs,
        ),
      ),
    );
  }

  // ── Exact-alarm permission ─────────────────────────────────────────────────

  Future<bool> requestExactAlarms() async {
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;
    bool can = await android.canScheduleExactNotifications() ?? false;
    if (!can) {
      await android.requestExactAlarmsPermission();
      can = await android.canScheduleExactNotifications() ?? false;
    }
    _canUseExact = can;
    return can;
  }

  // ── Diagnostics helpers ─────────────────────────────────────────────────────

  /// Read-only exact-alarms check (no permission dialog — unlike
  /// [requestExactAlarms]). Refreshes [canUseExactAlarms] as a side effect.
  Future<bool> checkExactAlarms() async {
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    _canUseExact = await android?.canScheduleExactNotifications() ?? false;
    return _canUseExact;
  }

  /// Whether the user currently allows this app to post notifications at all
  /// (the master toggle in Android Settings, or the first-launch prompt).
  Future<bool> areNotificationsEnabled() async {
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? false;
  }

  /// Re-shows the system notification-permission prompt (no-op if the user
  /// permanently denied it — then only Android Settings can re-enable).
  Future<bool> requestNotifications() async {
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  // ── Scheduled self-test ─────────────────────────────────────────────────────

  Future<void> scheduleTestIn(Duration delay) => _scheduleOneShot(
        id: _testScheduledId,
        when: DateTime.now().add(delay),
        channelId: kItemChannelId,
        title: 'Scheduled reminder works ⏰',
        body: 'This fired ${delay.inMinutes} min after you tapped it.',
      );

  // ── Global daily reminder ──────────────────────────────────────────────────

  Future<bool> scheduleDailyReminder(TimeOfDay time) => _scheduleDaily(
        id: _dailyReminderId,
        time: time,
        channelId: kDailyChannelId,
        title: 'Uplan',
        body: 'Time to check your habits and tasks for today 🎯',
      );

  Future<void> cancelDailyReminder() => _cancel(_dailyReminderId);

  Future<void> cancelAll() async {
    // No bulk cancel in alarm manager; clear the daily reminder (the common one).
    await _cancel(_dailyReminderId);
    await _plugin.cancelAll();
  }

  // ── Per-habit ───────────────────────────────────────────────────────────────

  Future<bool> scheduleHabitReminder(HabitModel habit) async {
    if (!habit.reminderEnabled || habit.reminderTime == null) return false;
    final TimeOfDay? time = _parseTime(habit.reminderTime!);
    if (time == null) return false;
    return _scheduleDaily(
      id: _habitId(habit.id),
      time: time,
      channelId: kItemChannelId,
      title: habit.name,
      body: 'Don\'t forget to mark your habit today ✅',
    );
  }

  Future<void> cancelHabitReminder(int habitId) => _cancel(_habitId(habitId));

  // ── Per-tracker ─────────────────────────────────────────────────────────────

  Future<bool> scheduleTrackerReminder(TrackerModel tracker) async {
    if (!tracker.reminderEnabled || tracker.reminderTime == null) return false;
    final TimeOfDay? time = _parseTime(tracker.reminderTime!);
    if (time == null) return false;
    return _scheduleDaily(
      id: _trackerId(tracker.id),
      time: time,
      channelId: kItemChannelId,
      title: '${tracker.icon} ${tracker.name}',
      body: 'Time to log your tracker 📋',
    );
  }

  Future<void> cancelTrackerReminder(int trackerId) =>
      _cancel(_trackerId(trackerId));

  // ── Per-task (one-shot per lead time) ───────────────────────────────────────

  Future<bool> scheduleTaskReminders(TaskModel task) async {
    await cancelTaskReminders(task.id);
    if (!task.reminderEnabled || task.dueDate == null) return false;
    final List<int> leadTimes = task.leadTimeMinutes;
    if (leadTimes.isEmpty) return false;

    DateTime due;
    try {
      due = DateTime.parse(task.dueDate!);
    } catch (_) {
      return false;
    }
    final TimeOfDay dueTime = _parseTime(task.dueTime ?? '09:00') ??
        const TimeOfDay(hour: 9, minute: 0);
    due = DateTime(due.year, due.month, due.day, dueTime.hour, dueTime.minute);

    bool any = false;
    for (int slot = 0; slot < leadTimes.length; slot++) {
      final DateTime fireTime =
          due.subtract(Duration(minutes: leadTimes[slot]));
      if (fireTime.isBefore(DateTime.now())) continue;
      await _scheduleOneShot(
        id: _taskId(task.id, slot),
        when: fireTime,
        channelId: kItemChannelId,
        title: task.title,
        body: 'Due ${_leadLabel(leadTimes[slot])} ⏰',
      );
      any = true;
    }
    return any;
  }

  Future<void> cancelTaskReminders(int taskId) async {
    for (int slot = 0; slot < 3; slot++) {
      await _cancel(_taskId(taskId, slot));
    }
  }

  // ── Reschedule on app start ───────────────────────────────────────────────

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

  // ── Alarm scheduling helpers ────────────────────────────────────────────────

  Future<void> _stash(int id, String channelId, String title, String body,
      {required bool repeat}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_kPrefPrefix$id',
      jsonEncode({
        'channel': channelId,
        'title': title,
        'body': body,
        'repeat': repeat,
      }),
    );
  }

  Future<void> _scheduleOneShot({
    required int id,
    required DateTime when,
    required String channelId,
    required String title,
    required String body,
  }) async {
    await _stash(id, channelId, title, body, repeat: false);
    await AndroidAlarmManager.oneShotAt(
      when,
      id,
      alarmNotificationCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  Future<bool> _scheduleDaily({
    required int id,
    required TimeOfDay time,
    required String channelId,
    required String title,
    required String body,
  }) async {
    await _stash(id, channelId, title, body, repeat: true);
    final DateTime now = DateTime.now();
    DateTime next =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return AndroidAlarmManager.periodic(
      const Duration(days: 1),
      id,
      alarmNotificationCallback,
      startAt: next,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
  }

  Future<void> _cancel(int id) async {
    await AndroidAlarmManager.cancel(id);
    await _plugin.cancel(id);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kPrefPrefix$id');
  }

  // ── Misc helpers ────────────────────────────────────────────────────────────

  TimeOfDay? _parseTime(String s) {
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _leadLabel(int minutes) {
    if (minutes >= 1440) {
      return 'in ${minutes ~/ 1440} day${minutes >= 2880 ? 's' : ''}';
    }
    if (minutes >= 60) {
      return 'in ${minutes ~/ 60} hour${minutes >= 120 ? 's' : ''}';
    }
    return 'in $minutes minute${minutes != 1 ? 's' : ''}';
  }
}
