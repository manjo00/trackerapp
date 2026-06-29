import 'dart:convert';
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

  /// Fully-qualified names of the native widget providers (package + class).
  static const String _androidProvider =
      'com.lifetracker.life_tracker.UplanWidgetProvider';
  static const String _agendaProvider =
      'com.lifetracker.life_tracker.UplanAgendaWidgetProvider';
  static const String _monthProvider =
      'com.lifetracker.life_tracker.UplanMonthWidgetProvider';

  // Month-cell colours (hex strings — parsed natively, avoids int overflow).
  static const String _monthDayBg = '#FFDEEDEF';
  static const String _monthDayFg = '#FF0F5B6B';
  static const String _monthNightBg = '#FFD7DBEC';
  static const String _monthNightFg = '#FF2E3270';
  static const String _monthWhiteFg = '#FFFFFFFF';
  static const String _monthTodayBg = '#33B39DDB'; // subtle highlight

  static const List<String> _fullMonths = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  // Agenda row colours (read on the widget's dark background).
  static const int _overdueColor = 0xFFE57373; // red
  static const int _todayColor = 0xFF8AB4F8; // blue
  static const int _laterColor = 0xFFB0B8C4; // muted

  /// How many days ahead the agenda widget looks.
  static const int _agendaHorizonDays = 7;

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

      // ── Agenda list (overdue + next week) for the agenda widget ────────
      final List<Map<String, dynamic>> agenda = _buildAgenda(tasks, now);

      // ── Month grid for the month widget ────────────────────────────────
      final allShifts = await ShiftsDao(db).getAllShifts();
      final Map<String, String> shiftTypeByDate = {
        for (final s in allShifts) s.date: s.shiftType,
      };
      final Set<String> taskDays = {
        for (final t in tasks)
          if (!t.isCompleted && t.dueDate != null) t.dueDate as String,
      };
      final List<Map<String, dynamic>> monthCells =
          _buildMonthCells(now, shiftTypeByDate, taskDays);

      // ── All dated tasks for the combined widget's side list ────────────
      final List<Map<String, dynamic>> combinedTasks =
          _buildCombinedTasks(tasks, now);

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
      await HomeWidget.saveWidgetData<String>(
          'agenda_items', jsonEncode(agenda));
      await HomeWidget.saveWidgetData<String>(
          'month_title', '${_fullMonths[now.month]} ${now.year}');
      await HomeWidget.saveWidgetData<String>(
          'month_cells', jsonEncode(monthCells));
      await HomeWidget.saveWidgetData<String>('widget_today', today);
      await HomeWidget.saveWidgetData<String>(
          'combined_tasks', jsonEncode(combinedTasks));

      await HomeWidget.updateWidget(qualifiedAndroidName: _androidProvider);
      await HomeWidget.updateWidget(qualifiedAndroidName: _agendaProvider);
      await HomeWidget.updateWidget(qualifiedAndroidName: _monthProvider);
    } catch (_) {
      // A widget refresh must never crash the app — swallow any failure.
    }
  }

  /// Builds the agenda widget's rows: incomplete tasks that are overdue or due
  /// within the next [_agendaHorizonDays], sorted by date (overdue first).
  static List<Map<String, dynamic>> _buildAgenda(
      List<dynamic> tasks, DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime horizon =
        today.add(const Duration(days: _agendaHorizonDays));

    final List<({String title, DateTime date})> raw = [];
    for (final t in tasks) {
      if (t.isCompleted || t.dueDate == null) continue;
      DateTime parsed;
      try {
        parsed = DateTime.parse(t.dueDate as String);
      } catch (_) {
        continue;
      }
      final DateTime d = DateTime(parsed.year, parsed.month, parsed.day);
      if (d.isAfter(horizon)) continue; // too far out
      raw.add((title: t.title as String, date: d));
    }
    raw.sort((a, b) => a.date.compareTo(b.date));

    return raw.take(25).map((it) {
      final int diff = it.date.difference(today).inDays;
      final String sub;
      final int color;
      if (diff < 0) {
        sub = 'Overdue · ${it.date.day} ${_months[it.date.month]}';
        color = _overdueColor;
      } else if (diff == 0) {
        sub = 'Today';
        color = _todayColor;
      } else if (diff == 1) {
        sub = 'Tomorrow';
        color = _laterColor;
      } else {
        sub = '${_weekdays[it.date.weekday]} ${it.date.day} ${_months[it.date.month]}';
        color = _laterColor;
      }
      return {'title': it.title, 'sub': sub, 'color': color};
    }).toList();
  }

  /// All incomplete tasks that have a due date, as { title, date, label },
  /// sorted by date. The native side re-sorts the selected day to the top.
  static List<Map<String, dynamic>> _buildCombinedTasks(
      List<dynamic> tasks, DateTime now) {
    final DateTime today = DateTime(now.year, now.month, now.day);

    final List<({String title, DateTime date})> raw = [];
    for (final t in tasks) {
      if (t.isCompleted || t.dueDate == null) continue;
      DateTime parsed;
      try {
        parsed = DateTime.parse(t.dueDate as String);
      } catch (_) {
        continue;
      }
      raw.add((
        title: t.title as String,
        date: DateTime(parsed.year, parsed.month, parsed.day),
      ));
    }
    raw.sort((a, b) => a.date.compareTo(b.date));

    return raw.map((it) {
      final int diff = it.date.difference(today).inDays;
      final String label;
      if (diff < 0) {
        label = 'Overdue · ${it.date.day} ${_months[it.date.month]}';
      } else if (diff == 0) {
        label = 'Today';
      } else if (diff == 1) {
        label = 'Tomorrow';
      } else {
        label =
            '${_weekdays[it.date.weekday]} ${it.date.day} ${_months[it.date.month]}';
      }
      return {'title': it.title, 'date': _dateKey(it.date), 'label': label};
    }).toList();
  }

  /// Builds the month-grid cells for the current month: leading blanks, then
  /// one cell per day with shift colours + a task dot. Colours are hex strings
  /// (parsed natively) to avoid 32-bit int overflow over the platform channel.
  static List<Map<String, dynamic>> _buildMonthCells(
    DateTime now,
    Map<String, String> shiftTypeByDate,
    Set<String> taskDays,
  ) {
    final DateTime first = DateTime(now.year, now.month, 1);
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final int leading = first.weekday - 1; // Monday = 1 → 0 blanks
    final String todayStr = _dateKey(DateTime(now.year, now.month, now.day));

    final List<Map<String, dynamic>> cells = [];
    for (int i = 0; i < leading; i++) {
      cells.add({'day': 0});
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final String ds = _dateKey(DateTime(now.year, now.month, d));
      final String? type = shiftTypeByDate[ds];
      String bg = '';
      String fg = _monthWhiteFg;
      if (type == 'day') {
        bg = _monthDayBg;
        fg = _monthDayFg;
      } else if (type == 'night') {
        bg = _monthNightBg;
        fg = _monthNightFg;
      } else if (ds == todayStr) {
        bg = _monthTodayBg;
      }
      cells.add({
        'day': d,
        'date': ds,
        'bg': bg,
        'fg': fg,
        'dot': taskDays.contains(ds),
      });
    }
    return cells;
  }
}
