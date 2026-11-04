/// What one day is for one habit: kept, missed, not due, a break, … Pure
/// Dart; the streak and strength in `habit_stats.dart` are built on it.
library;

import '../data/models/habit_model.dart';
import 'habit_day.dart';
import 'habit_types.dart';

/// The state of one habit on one day.
///
/// `open` is a day that asks nothing: a "few times a week" day without a tick
/// (the week decides, not the day), or a day after today.
enum DayState {
  beforeStart,
  notDue,
  open,
  away,
  rest,
  sick,
  kept,
  partial,
  missed,
  pending,
}

/// The habit's first day: the habit day it was created on.
String firstDayOf(HabitModel h) => habitDayOf(h.createdAt);

/// Whether [day] is one of the habit's days. Every day for "every day" and
/// "a few times a week" (the week's count decides in [dayState]); by shift
/// counts as every day until demo 3 reads the work schedule.
bool isScheduledOn(HabitModel h, String day) => switch (h.schedule) {
      HabitSchedule.weekdays =>
        h.weekdayMask & (1 << (weekdayOf(day) - 1)) != 0,
      HabitSchedule.daily || HabitSchedule.perWeek || HabitSchedule.shifts =>
        true,
    };

/// A saved day that keeps the habit: done, and at its goal for a count.
bool isKeptEntry(HabitModel h, HabitEntry? e) =>
    e != null &&
    e.status == EntryStatus.done &&
    e.value >= (h.kind == HabitKind.count ? h.goal : 1);

/// Kept days in [weekStart]'s week from the habit's first day up to and
/// including [upTo].
int keptDaysInWeek(HabitModel h, HabitHistory hist, String weekStart,
    {required String upTo}) {
  final String first = firstDayOf(h);
  final String last = addDays(weekStart, 6);
  int kept = 0;
  for (String d = weekStart;
      d.compareTo(upTo) <= 0 && d.compareTo(last) <= 0;
      d = addDays(d, 1)) {
    if (d.compareTo(first) >= 0 && isKeptEntry(h, hist.entries[d])) kept++;
  }
  return kept;
}

/// What [day] is for habit [h], given its history and [today].
DayState dayState(HabitModel h, HabitHistory hist, String day,
    {required String today, required bool weekStartsSunday}) {
  if (day.compareTo(firstDayOf(h)) < 0) return DayState.beforeStart;
  final HabitEntry? entry = hist.entries[day];
  if (entry?.status == EntryStatus.rest) return DayState.rest;
  if (entry?.status == EntryStatus.sick) return DayState.sick;
  if (isKeptEntry(h, entry)) return DayState.kept;
  if (hist.pauses.any((PauseRange p) => p.contains(day))) {
    return DayState.away;
  }
  if (h.schedule == HabitSchedule.perWeek) {
    final String weekStart =
        weekStartOf(day, weekStartsSunday: weekStartsSunday);
    final int before = day == weekStart
        ? 0
        : keptDaysInWeek(h, hist, weekStart, upTo: addDays(day, -1));
    if (before >= (h.perWeek ?? 1)) return DayState.notDue;
  }
  if (!isScheduledOn(h, day)) return DayState.notDue;
  if (entry != null && entry.value > 0) return DayState.partial;
  if (day == today) return DayState.pending;
  if (day.compareTo(today) > 0) return DayState.open;
  if (h.schedule == HabitSchedule.perWeek) return DayState.open;
  return DayState.missed;
}
