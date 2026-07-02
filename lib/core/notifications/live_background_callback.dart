import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:home_widget/home_widget.dart';

import '../../features/habits/data/dao/habits_dao.dart';
import '../../features/tasks/data/dao/tasks_dao.dart';
import '../database/app_database.dart';
import 'live_dashboard_service.dart';

/// Background handler for the live-notification action buttons (✓ / snooze).
///
/// When a button is tapped, home_widget's HomeWidgetBackgroundReceiver spins
/// up a headless Flutter engine (no UI) and runs this function with the
/// button's uri — works even when the app is fully closed. Same pattern as
/// the alarm-reminder callback.
///
/// Uri shape: `uplan://live?action=complete|snooze&type=task|habit|inbox&id=N`
///
/// Registered from main.dart via [HomeWidget.registerInteractivityCallback].
@pragma('vm:entry-point')
Future<void> liveBackgroundCallback(Uri? uri) async {
  if (uri == null || uri.host != 'live') return;

  final String? action = uri.queryParameters['action'];
  final String? type = uri.queryParameters['type'];
  final int? id = int.tryParse(uri.queryParameters['id'] ?? '');
  if (action == null || type == null || id == null) return;

  // This isolate has no Riverpod scope — open our own connection and close
  // it when done. SQLite handles the app's connection + this one safely;
  // the write is short-lived.
  final AppDatabase db = AppDatabase();
  try {
    final DateTime now = DateTime.now();
    final String today = _dateKey(now);

    switch (action) {
      case 'complete':
        if (type == 'habit') {
          final HabitsDao dao = HabitsDao(db);
          if (!await dao.isCompletedOn(id, today)) {
            await dao.insertCompletion(HabitCompletionsCompanion(
              habitId: Value(id),
              date: Value(today),
            ));
          }
        } else {
          // 'task' and 'inbox' are both rows in the tasks table.
          await TasksDao(db).updateTask(TasksCompanion(
            id: Value(id),
            isCompleted: const Value(true),
          ));
        }

      case 'snooze':
        await _snooze(db, type, id, now);
    }

    // Rebuild the slideshow so the handled card disappears. The native
    // service watches the prefs file and re-renders on this write.
    await LiveDashboardService.syncCards(db);
  } catch (_) {
    // A failed action must never crash the background engine — worst case
    // the card simply stays until the next sync.
  } finally {
    await db.close();
  }
}

/// Snooze behaviour, per the user's Settings choice:
///   hide1h (default) — hide the card for an hour, nothing else changes.
///   tomorrow         — push the task's due date to tomorrow (habits fall
///                      back to hiding until midnight — they have no date).
Future<void> _snooze(AppDatabase db, String type, int id, DateTime now) async {
  final String mode =
      await HomeWidget.getWidgetData<String>('live_snooze_mode') ?? 'hide1h';

  if (mode == 'tomorrow' && type != 'habit') {
    final DateTime tomorrow = now.add(const Duration(days: 1));
    await TasksDao(db).updateTask(TasksCompanion(
      id: Value(id),
      dueDate: Value(_dateKey(tomorrow)),
    ));
    return;
  }

  // Prefs-only hide: card comes back when the timestamp expires.
  final DateTime until = type == 'habit' && mode == 'tomorrow'
      ? DateTime(now.year, now.month, now.day + 1) // midnight
      : now.add(const Duration(hours: 1));

  final Map<String, dynamic> snoozes = _decodeMap(
      await HomeWidget.getWidgetData<String>('live_snoozes'));
  snoozes['$type:$id'] = until.millisecondsSinceEpoch;
  await HomeWidget.saveWidgetData<String>(
      'live_snoozes', jsonEncode(snoozes));
}

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Map<String, dynamic> _decodeMap(String? json) {
  if (json == null || json.isEmpty) return {};
  try {
    final decoded = jsonDecode(json);
    return decoded is Map<String, dynamic> ? decoded : {};
  } on FormatException {
    return {};
  }
}
