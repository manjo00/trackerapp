import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/habits/data/dao/habits_dao.dart';
import '../../features/shifts/data/dao/shifts_dao.dart';
import '../../features/shifts/data/models/work_shift_model.dart';
import '../../features/tasks/data/dao/tasks_dao.dart';
import '../database/app_database.dart';
import '../utils/week_utils.dart';
import 'widget_payload.dart';

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

  // Month-cell text colours (hex strings — parsed natively). The rounded tile
  // fills live in drawables (uplan_cell_day/night/today); these are the matching
  // dark text colours for the day number + rotation label.
  static const String _monthDayFg = '#FF06414D';
  static const String _monthNightFg = '#FF1E2156';
  static const String _monthWhiteFg = '#FFFFFFFF';

  static const List<String> _fullMonths = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  // Agenda row colours (read on the widget's dark background).
  /// How many days ahead the agenda widget looks. Generous on purpose — the
  /// rows have to stay useful on days the app never runs — and the list is
  /// capped at 25 nearest rows anyway.
  static const int _agendaHorizonDays = 30;

  // Light accent colours that read on the widget's dark background.
  static const int _dayColor = 0xFF5FC6D8; // cyan
  static const int _nightColor = 0xFFA6ABEC; // periwinkle

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Task priority (0 low / 1 med / 2 high) → dot colour hex.
  static String _priorityHex(int p) => switch (p) {
        2 => '#FFE07070', // high — soft red
        0 => '#FF8E9AAF', // low — muted slate
        _ => '#FFFFB347', // medium — warm amber
      };

  static Future<void> sync(AppDatabase db) async {
    try {
      final DateTime now = DateTime.now();
      final String today = _dateKey(now);

      // ── Habits remaining today ─────────────────────────────────────────
      final HabitsDao habitsDao = HabitsDao(db);
      final habits = await habitsDao.getAllHabits();
      int habitsLeft = 0;
      for (final h in habits) {
        if (!await habitsDao.isCompletedOn(h.id, today)) habitsLeft++;
      }

      // ── Tasks due today (incomplete) ───────────────────────────────────
      // Tasks due today are counted natively from `combined_tasks` (every row
      // carries its date), so no count for them is pushed.
      final tasks = await TasksDao(db).getAllTasks();

      // ── Agenda list (overdue + next week) for the agenda widget ────────
      final List<Map<String, dynamic>> agenda = _buildAgenda(tasks, now);

      // ── Month grid for the month widget ────────────────────────────────
      final allShifts = await ShiftsDao(db).getAllShifts();
      final Map<String, String> shiftTypeByDate = {
        for (final s in allShifts) s.date: s.shiftType,
      };
      // Shifts keyed by date over a short window, so the glance can show the
      // right one on any day it is read rather than only the day it was built.
      final Map<String, Map<String, String>> shiftByDate = {};
      for (int off = -1; off <= 14; off++) {
        final String key = _dateKey(now.add(Duration(days: off)));
        final row = allShifts.where((s) => s.date == key).firstOrNull;
        if (row == null) continue;
        final ShiftType type = ShiftType.fromString(row.shiftType);
        shiftByDate[key] = {
          't': '${type.label} \u00B7 ${row.startTime}\u2013${row.endTime}',
          'c': argbToHex(type == ShiftType.day ? _dayColor : _nightColor),
        };
      }
      // Rotation label per date (for the month widget tiles).
      final Map<String, String> rotationByDate = {
        for (final s in allShifts)
          if (s.rotationLabel != null && (s.rotationLabel as String).isNotEmpty)
            s.date: s.rotationLabel as String,
      };
      // Per-day priority dot colours (most urgent first, up to 3).
      final Map<String, List<({int p, String hex})>> dotsTmp = {};
      for (final t in tasks) {
        if (t.isCompleted || t.dueDate == null) continue;
        (dotsTmp[t.dueDate as String] ??= [])
            .add((p: t.priority, hex: _priorityHex(t.priority)));
      }
      final Map<String, List<String>> dotsByDate = {
        for (final e in dotsTmp.entries)
          e.key: (e.value..sort((a, b) => b.p.compareTo(a.p)))
              .take(3)
              .map((x) => x.hex)
              .toList(),
      };
      // Build a range of months (last month → +3) so the widget arrows can
      // navigate without re-querying. Keyed by "yyyy-MM".
      // Read the week-start setting straight from prefs — this also runs in
      // the headless background isolate where no provider scope exists.
      final bool sundayStart = (await SharedPreferences.getInstance())
              .getBool('week_starts_sunday') ??
          false;
      final Map<String, List<Map<String, dynamic>>> monthCellsMap = {};
      final Map<String, String> monthTitlesMap = {};
      for (int off = -1; off <= 3; off++) {
        final DateTime m = DateTime(now.year, now.month + off, 1);
        final String key =
            '${m.year}-${m.month.toString().padLeft(2, '0')}';
        monthCellsMap[key] = _buildMonthCells(
            m, shiftTypeByDate, dotsByDate, rotationByDate,
            sundayStart: sundayStart);
        monthTitlesMap[key] = '${_fullMonths[m.month]} ${m.year}';
      }
      final String currentKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final List<Map<String, dynamic>> monthCells =
          monthCellsMap[currentKey] ?? const [];

      // ── All dated tasks for the combined widget's side list ────────────
      final List<Map<String, dynamic>> combinedTasks =
          _buildCombinedTasks(tasks, now);

      // Nothing below is phrased relative to today. Every date-dependent thing
      // the widgets show - the ring on the calendar, "Today"/"Overdue", the
      // header, the shift, the counts - is worked out natively while drawing
      // (WidgetDates.kt), so the display stays right on a day the app never
      // ran. `snapshot_date` records when this data was gathered, which is how
      // the native side knows a habit count belongs to an older day.
      final Map<String, Object> payload = {
        'shift_by_date': jsonEncode(shiftByDate),
        'habits_left': habitsLeft,
        'habits_total': habits.length,
        'snapshot_date': today,
        'agenda_items': jsonEncode(agenda),
        'month_title': '${_fullMonths[now.month]} ${now.year}',
        'month_cells': jsonEncode(monthCells),
        'month_cells_map': jsonEncode(monthCellsMap),
        'month_titles_map': jsonEncode(monthTitlesMap),
        // Weekday header letters in display order, so the native header row
        // tracks the Sunday/Monday-start setting (was hardcoded Monday-start,
        // which shifted the dates under the wrong columns on Sunday-start).
        'month_dow': weekdayHeaderLetters(sundayStart: sundayStart).join(','),
        'combined_tasks': jsonEncode(combinedTasks),
      };

      // Say nothing when there is nothing new to say. sync() runs on launch, on
      // every resume and on every pause, so most calls carry an identical
      // payload - and a push costs a dozen preference commits plus three widget
      // redraws, each of which re-runs its collection factories from scratch.
      final String stamp = payloadChecksum(jsonEncode(payload));
      final String? previous =
          await HomeWidget.getWidgetData<String>('widget_payload_stamp');
      if (previous == stamp) return;

      for (final MapEntry<String, Object> entry in payload.entries) {
        final Object value = entry.value;
        if (value is int) {
          await HomeWidget.saveWidgetData<int>(entry.key, value);
        } else {
          await HomeWidget.saveWidgetData<String>(entry.key, value as String);
        }
      }
      await HomeWidget.saveWidgetData<String>('widget_payload_stamp', stamp);

      await HomeWidget.updateWidget(qualifiedAndroidName: _androidProvider);
      await HomeWidget.updateWidget(qualifiedAndroidName: _agendaProvider);
      await HomeWidget.updateWidget(qualifiedAndroidName: _monthProvider);
    } catch (_) {
      // A widget refresh must never crash the app — swallow any failure.
    }
  }

  /// Builds the agenda widget's rows: incomplete tasks that are overdue or due
  /// within the next [_agendaHorizonDays], sorted by date (overdue first). Each
  /// row carries its raw date; the relative line ("Today", "Overdue") and its
  /// colour are worked out natively at draw time.
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

    return raw
        .take(25)
        .map((it) => {'title': it.title, 'date': _dateKey(it.date)})
        .toList();
  }

  /// All incomplete tasks that have a due date, as { title, date, color },
  /// sorted by date. The native side re-sorts the selected day to the top and
  /// writes each date's headline ("Today", "Overdue") itself, so the list keeps
  /// reading correctly on a day the app never ran.
  static List<Map<String, dynamic>> _buildCombinedTasks(
      List<dynamic> tasks, DateTime now) {
    final List<({String title, DateTime date, String color})> raw = [];
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
        color: _priorityHex(t.priority),
      ));
    }
    raw.sort((a, b) => a.date.compareTo(b.date));

    return raw
        .map((it) => {
              'title': it.title,
              'date': _dateKey(it.date),
              'color': it.color,
            })
        .toList();
  }

  /// Builds the month-grid cells for the current month: leading blanks, then
  /// one cell per day with shift colours + a task dot. Colours are hex strings
  /// (parsed natively) to avoid 32-bit int overflow over the platform channel.
  ///
  /// Deliberately says nothing about which day is *today*: the native factory
  /// decides that against the clock as it draws (see WidgetDates.kt). Baking it
  /// here left the ring on yesterday whenever the app hadn't run since
  /// midnight.
  static List<Map<String, dynamic>> _buildMonthCells(
    DateTime month,
    Map<String, String> shiftTypeByDate,
    Map<String, List<String>> dotsByDate,
    Map<String, String> rotationByDate, {
    required bool sundayStart,
  }) {
    final DateTime first = DateTime(month.year, month.month, 1);
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final int leading = monthLeadingBlanks(first, sundayStart: sundayStart);

    final List<Map<String, dynamic>> cells = [];
    for (int i = 0; i < leading; i++) {
      cells.add({'day': 0});
    }
    for (int d = 1; d <= daysInMonth; d++) {
      final String ds = _dateKey(DateTime(month.year, month.month, d));
      final String? type = shiftTypeByDate[ds];
      String kind = '';
      String fg = _monthWhiteFg;
      if (type == 'day') {
        kind = 'day';
        fg = _monthDayFg;
      } else if (type == 'night') {
        kind = 'night';
        fg = _monthNightFg;
      }
      cells.add({
        'day': d,
        'date': ds,
        'kind': kind,
        'fg': fg,
        'rot': rotationByDate[ds] ?? '',
        'dots': dotsByDate[ds] ?? const <String>[],
      });
    }
    return cells;
  }
}
