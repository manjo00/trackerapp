import 'package:home_widget/home_widget.dart';
import '../../features/habits/data/dao/habits_dao.dart';
import '../../features/shifts/data/dao/shifts_dao.dart';
import '../../features/shifts/data/models/work_shift_model.dart';
import '../../features/tasks/data/dao/tasks_dao.dart';
import '../database/app_database.dart';

/// Pushes a "Today" snapshot to the native home-screen widget.
///
/// The widget itself is native (see UplanWidgetProvider.kt). All this does is
/// gather a few values and hand them over via [HomeWidget.saveWidgetData];
/// the native side reads them on its next update.
///
/// Cheap, one-shot queries — safe to call on launch, on resume, and when the
/// app is backgrounded (so the home screen reflects the latest state).
class HomeWidgetService {
  const HomeWidgetService._();

  /// Fully-qualified name of the native provider (package + class).
  static const String _androidProvider =
      'com.lifetracker.life_tracker.UplanWidgetProvider';

  // Light accent colours that read on the widget's dark background.
  static const int _dayColor = 0xFF5FC6D8; // cyan
  static const int _nightColor = 0xFFA6ABEC; // periwinkle
  static const int _restColor = 0xFFBFC4CC; // muted grey

  static const List<String> _weekdays = [
    '', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];
  static const List<String> _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<void> sync(AppDatabase db) async {
    try {
      final DateTime now = DateTime.now();
      final String today = _dateKey(now);

      // ── Shift for today ────────────────────────────────────────────────
      final shiftRow = await ShiftsDao(db).getShiftForDate(today);
      final String shiftText;
      final int shiftColor;
      if (shiftRow == null) {
        shiftText = 'Rest day';
        shiftColor = _restColor;
      } else {
        final ShiftType type = ShiftType.fromString(shiftRow.shiftType);
        shiftText =
            '${type.label} · ${shiftRow.startTime}–${shiftRow.endTime}';
        shiftColor = type == ShiftType.day ? _dayColor : _nightColor;
      }

      // ── Habits remaining today ─────────────────────────────────────────
      final HabitsDao habitsDao = HabitsDao(db);
      final habits = await habitsDao.getAllHabits();
      int habitsLeft = 0;
      for (final h in habits) {
        if (!await habitsDao.isCompletedOn(h.id, today)) habitsLeft++;
      }

      // ── Tasks due today (incomplete) ───────────────────────────────────
      final tasks = await TasksDao(db).getAllTasks();
      final int tasksDue =
          tasks.where((t) => t.dueDate == today && !t.isCompleted).length;

      final String counts;
      if (habitsLeft == 0 && tasksDue == 0) {
        counts = 'All done for today 🎉';
      } else {
        counts = '$habitsLeft habit${habitsLeft == 1 ? '' : 's'} left'
            ' · $tasksDue task${tasksDue == 1 ? '' : 's'} due';
      }

      final String dateText =
          '${_weekdays[now.weekday]}, ${_months[now.month]} ${now.day}';

      // ── Hand the values to the native widget ───────────────────────────
      await HomeWidget.saveWidgetData<String>('today_date', dateText);
      await HomeWidget.saveWidgetData<String>('today_shift', shiftText);
      await HomeWidget.saveWidgetData<int>('today_shift_color', shiftColor);
      await HomeWidget.saveWidgetData<String>('today_counts', counts);
      await HomeWidget.updateWidget(qualifiedAndroidName: _androidProvider);
    } catch (_) {
      // A widget refresh must never crash the app — swallow any failure.
    }
  }
}
