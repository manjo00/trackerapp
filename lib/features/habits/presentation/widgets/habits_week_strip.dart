import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shifts/data/models/work_shift_model.dart';
import '../../domain/habit_day.dart';
import '../../domain/habit_rules.dart';
import '../models/habit_day_view.dart';

/// Whether [day] can be picked in the week strip: today, or a past day of
/// this week or last week (so yesterday is there on a week's first day too).
bool isPickableDay(String day,
        {required String today, required bool weekStartsSunday}) =>
    day.compareTo(today) <= 0 &&
    day.compareTo(addDays(
            weekStartOf(today, weekStartsSunday: weekStartsSunday), -7)) >=
        0;

/// A week at a glance: 7 days, each a ring of how much of that day's due
/// habits were kept, the date inside, and a sun or moon for a day or night
/// shift under it. Today sits on a soft pill.
///
/// With [onPick] the days up to today can be tapped to show that day, and
/// the picked day ([selected]) sits on a stronger pill; with [onWeek] the
/// ‹ and › arrows switch between this week and last week. Without them the
/// strip only shows.
class HabitsWeekStrip extends StatelessWidget {
  const HabitsWeekStrip({
    required this.views,
    required this.today,
    required this.shifts,
    required this.weekStartsSunday,
    this.selected,
    this.weekOffset = 0,
    this.onPick,
    this.onWeek,
    super.key,
  });

  final List<HabitDayView> views;
  final String today;
  final Map<String, WorkShiftModel> shifts;
  final bool weekStartsSunday;

  /// The day the list shows, or null for today.
  final String? selected;

  /// 0 shows this week, -1 last week.
  final int weekOffset;

  /// Called with a tapped day: today, or a past day within the limit.
  final ValueChanged<String>? onPick;

  /// Called with -1 (‹, last week) or 0 (›, this week).
  final ValueChanged<int>? onWeek;

  /// Kept ÷ due for [day]; 0 when nothing was due.
  double _share(String day) {
    int kept = 0;
    int due = 0;
    for (final HabitDayView v in views) {
      final DayState s = dayState(v.habit, v.history, day,
          today: today, weekStartsSunday: weekStartsSunday);
      if (s == DayState.kept) kept++;
      if (s == DayState.kept ||
          s == DayState.partial ||
          s == DayState.missed ||
          s == DayState.pending) {
        due++;
      }
    }
    return due == 0 ? 0 : kept / due;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String start = addDays(
        weekStartOf(today, weekStartsSunday: weekStartsSunday),
        7 * weekOffset);
    final ValueChanged<int>? week = onWeek;
    return Padding(
      padding: EdgeInsets.fromLTRB(week == null ? 10 : 2, 0,
          week == null ? 10 : 2, 12),
      child: Row(
        children: [
          if (week != null)
            _arrow(Icons.chevron_left_rounded, 'Last week',
                weekOffset == 0 ? () => week(-1) : null),
          for (int i = 0; i < 7; i++)
            Expanded(child: _day(context, cs, addDays(start, i))),
          if (week != null)
            _arrow(Icons.chevron_right_rounded, 'This week',
                weekOffset == 0 ? null : () => week(0)),
        ],
      ),
    );
  }

  Widget _arrow(IconData icon, String tooltip, VoidCallback? onPressed) =>
      IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 48),
      );

  Widget _day(BuildContext context, ColorScheme cs, String day) {
    final bool isToday = day == today;
    final bool picked = selected != null && selected != today && day == selected;
    final ValueChanged<String>? pick = onPick;
    final VoidCallback? onTap = pick != null &&
            isPickableDay(day, today: today, weekStartsSunday: weekStartsSunday)
        ? () => pick(day)
        : null;
    final DateTime date = DateTime.parse(day);
    final ShiftType? shift = shifts[day]?.type;
    final TextStyle? small = Theme.of(context).textTheme.labelSmall;
    final Color text = picked
        ? cs.onPrimaryContainer
        : isToday
            ? cs.onSurface
            : cs.onSurfaceVariant;
    return Semantics(
      label: '${isToday ? 'Today, ' : ''}${DateFormat('EEEE d MMMM').format(date)}',
      button: onTap != null,
      selected: picked,
      onTap: onTap,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Material(
          color: picked
              ? cs.primaryContainer
              : isToday
                  ? cs.surfaceContainerLow
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(DateFormat('E').format(date).substring(0, 1),
                      style: small?.copyWith(color: text)),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: day.compareTo(today) > 0 ? 0 : _share(day),
                            strokeWidth: 3,
                            backgroundColor: cs.outlineVariant,
                            color: cs.primary,
                          ),
                        ),
                        Text('${date.day}', style: small?.copyWith(color: text)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 14,
                    child: switch (shift) {
                      ShiftType.day => Icon(Icons.light_mode_rounded,
                          size: 13, color: Colors.amber.shade700),
                      ShiftType.night => Icon(Icons.dark_mode_rounded,
                          size: 13, color: cs.primary),
                      null => null,
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
