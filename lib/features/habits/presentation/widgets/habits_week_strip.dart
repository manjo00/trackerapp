import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../shifts/data/models/work_shift_model.dart';
import '../../domain/habit_day.dart';
import '../../domain/habit_rules.dart';
import '../models/habit_day_view.dart';

/// This week at a glance: 7 days, each a ring of how much of that day's due
/// habits were kept, the date inside, and a sun or moon for a day or night
/// shift under it. Today sits on a soft pill. Display only in demo 1.
class HabitsWeekStrip extends StatelessWidget {
  const HabitsWeekStrip({
    required this.views,
    required this.today,
    required this.shifts,
    required this.weekStartsSunday,
    super.key,
  });

  final List<HabitDayView> views;
  final String today;
  final Map<String, WorkShiftModel> shifts;
  final bool weekStartsSunday;

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
    final String start = weekStartOf(today, weekStartsSunday: weekStartsSunday);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      child: Row(
        children: [
          for (int i = 0; i < 7; i++)
            Expanded(child: _day(context, cs, addDays(start, i))),
        ],
      ),
    );
  }

  Widget _day(BuildContext context, ColorScheme cs, String day) {
    final bool isToday = day == today;
    final DateTime date = DateTime.parse(day);
    final ShiftType? shift = shifts[day]?.type;
    final TextStyle? small = Theme.of(context).textTheme.labelSmall;
    return Semantics(
      label: '${isToday ? 'Today, ' : ''}${DateFormat('EEEE d MMMM').format(date)}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: isToday
            ? BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(DateFormat('E').format(date).substring(0, 1),
                style: small?.copyWith(
                    color: isToday ? cs.onSurface : cs.onSurfaceVariant)),
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
                  Text('${date.day}', style: small),
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
    );
  }
}
