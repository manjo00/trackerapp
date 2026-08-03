import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';

/// The kinds of block the Home dashboard can show.
///
/// The user's layout is an ordered list of these, stored in preferences
/// by name (see SettingsNotifier). A type absent from the list is simply
/// not shown; the Edit Home screen offers it under "Add block".
enum HomeBlockType {
  urgent,
  dueToday,
  captured,
  thisWeek,
  workout,
  notes,

  /// Renders one chosen note's content inline (v21). May appear multiple
  /// times (different notes); config `{"noteId": …}`.
  pinnedNote,

  /// One chosen list's incomplete tasks (config `{"listId": …}`). Multi.
  list,

  /// Incomplete tasks carrying one label (config `{"labelId": …}`). Multi.
  label,

  /// Today's habits with check-off.
  habits,

  /// Today's shift + the next upcoming one, at a glance.
  shift,

  /// Completed (not yet archived) tasks — see what got done, un-tick
  /// mistakes. The check circle on a tile un-completes as usual.
  done;

  String get title => switch (this) {
        urgent => 'Urgent',
        dueToday => 'Due today',
        captured => 'Captured',
        thisWeek => 'This week',
        workout => 'Workout',
        notes => 'Notes',
        pinnedNote => 'Pinned note',
        list => kListNoun,
        label => 'Label',
        habits => 'Habits',
        shift => 'Shift',
        done => 'Done',
      };

  IconData get icon => switch (this) {
        urgent => Icons.local_fire_department_rounded,
        dueToday => Icons.today_rounded,
        captured => Icons.inbox_rounded,
        thisWeek => Icons.view_week_rounded,
        workout => Icons.fitness_center_rounded,
        notes => Icons.sticky_note_2_rounded,
        pinnedNote => Icons.push_pin_rounded,
        list => Icons.list_alt_rounded,
        label => Icons.label_rounded,
        habits => Icons.repeat_rounded,
        shift => Icons.work_history_rounded,
        done => Icons.task_alt_rounded,
      };

  /// Types that may appear on Home more than once (each instance pointing at
  /// a different note/list/label). Everything else is single-instance.
  static const Set<HomeBlockType> multiInstance = {pinnedNote, list, label};

  /// Shipped layout — the original blocks with workout then notes appended, so
  /// existing users see what they had plus the new blocks at the bottom.
  static const List<HomeBlockType> defaults = [
    urgent,
    dueToday,
    captured,
    thisWeek,
    workout,
    notes,
  ];

  /// Parses a stored layout. Unknown names are dropped and duplicates
  /// collapse to their first occurrence. A null [raw] (nothing stored yet)
  /// yields [defaults]; an explicit empty list stays empty — the user
  /// removed every block on purpose.
  static List<HomeBlockType> parse(List<String>? raw) {
    if (raw == null) return defaults;
    final List<HomeBlockType> result = [];
    for (final String name in raw) {
      final HomeBlockType? type =
          values.where((t) => t.name == name).firstOrNull;
      if (type != null && !result.contains(type)) result.add(type);
    }
    return result;
  }
}
