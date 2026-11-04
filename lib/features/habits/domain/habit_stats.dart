/// The numbers a habit shows: its streak, its strength %, this week's count
/// and the spare days left. Pure Dart, built on [dayState].
///
/// - **Streak:** due days kept in a row (weeks for "a few times a week").
///   Today not done yet never breaks it; breaks and days not due are skipped;
///   a miss uses a spare day while that week has one.
/// - **Strength:** a slow average: each finished due day moves it 1/20 of the
///   way toward kept (1) or missed (0); a week moves it 1/6 for "a few times
///   a week". One miss never wipes it out.
library;

import 'dart:math' as math;

import '../data/models/habit_model.dart';
import 'habit_day.dart';
import 'habit_rules.dart';
import 'habit_types.dart';

enum StreakUnit { days, weeks }

/// Everything a habit's row needs about today.
class HabitSummary {
  const HabitSummary({
    required this.today,
    required this.todayValue,
    required this.streak,
    required this.streakUnit,
    required this.strengthPercent,
    required this.weekCount,
    required this.sparesLeft,
  });

  final DayState today;
  final int todayValue;
  final int streak;
  final StreakUnit streakUnit;
  final int strengthPercent;
  final int weekCount;
  final int sparesLeft;
}

/// How far back the numbers look. Older days no longer move the strength
/// (0.95^400 ≈ 0), so a habit's history is read for this window only.
const int kHabitWindowDays = 400;

String _firstCountedDay(HabitModel h, String today) {
  final String first = firstDayOf(h);
  final String windowStart = addDays(today, -kHabitWindowDays);
  return first.compareTo(windowStart) > 0 ? first : windowStart;
}

bool _allAway(HabitHistory hist, String weekStart) {
  for (int i = 0; i < 7; i++) {
    final String d = addDays(weekStart, i);
    if (!hist.pauses.any((PauseRange p) => p.contains(d))) return false;
  }
  return true;
}

/// The running streak on [today].
int currentStreak(HabitModel h, HabitHistory hist,
    {required String today, required bool weekStartsSunday}) {
  if (h.schedule == HabitSchedule.perWeek) {
    return _weekStreak(h, hist, today, weekStartsSunday);
  }
  final String start = _firstCountedDay(h, today);
  final Map<String, int> sparesUsed = {};
  int streak = 0;
  for (String d = today; d.compareTo(start) >= 0; d = addDays(d, -1)) {
    final DayState s =
        dayState(h, hist, d, today: today, weekStartsSunday: weekStartsSunday);
    if (s == DayState.kept) {
      streak++;
    } else if (s == DayState.missed || (s == DayState.partial && d != today)) {
      final String week = weekStartOf(d, weekStartsSunday: weekStartsSunday);
      final int used = sparesUsed[week] ?? 0;
      if (used >= h.sparesPerWeek) return streak;
      sparesUsed[week] = used + 1;
    } else if (s == DayState.beforeStart) {
      return streak;
    }
    // pending, today's partial, open, not due, away, rest, sick: skipped.
  }
  return streak;
}

int _weekStreak(
    HabitModel h, HabitHistory hist, String today, bool weekStartsSunday) {
  final int n = h.perWeek ?? 1;
  final String firstWeek = weekStartOf(_firstCountedDay(h, today),
      weekStartsSunday: weekStartsSunday);
  String week = weekStartOf(today, weekStartsSunday: weekStartsSunday);
  int streak = keptDaysInWeek(h, hist, week, upTo: today) >= n ? 1 : 0;
  for (week = addDays(week, -7);
      week.compareTo(firstWeek) >= 0;
      week = addDays(week, -7)) {
    if (keptDaysInWeek(h, hist, week, upTo: addDays(week, 6)) >= n) {
      streak++;
    } else if (!_allAway(hist, week)) {
      break;
    }
  }
  return streak;
}

/// The strength on [today], 0–100.
int strengthPercent(HabitModel h, HabitHistory hist,
    {required String today, required bool weekStartsSunday}) {
  final String start = _firstCountedDay(h, today);
  double s = 0;
  if (h.schedule == HabitSchedule.perWeek) {
    final int n = h.perWeek ?? 1;
    final String thisWeek =
        weekStartOf(today, weekStartsSunday: weekStartsSunday);
    for (String week = weekStartOf(start, weekStartsSunday: weekStartsSunday);
        week.compareTo(thisWeek) <= 0;
        week = addDays(week, 7)) {
      final bool current = week == thisWeek;
      final int kept = keptDaysInWeek(h, hist, week,
          upTo: current ? today : addDays(week, 6));
      if (current && kept < n) break; // a running week counts once reached
      if (kept < n && _allAway(hist, week)) continue;
      s += (math.min(1, kept / n) - s) / 6;
    }
  } else {
    for (String d = start; d.compareTo(today) <= 0; d = addDays(d, 1)) {
      final DayState state = dayState(h, hist, d,
          today: today, weekStartsSunday: weekStartsSunday);
      double? v;
      if (state == DayState.kept) {
        v = 1;
      } else if (d == today) {
        v = null; // today counts once kept
      } else if (state == DayState.missed) {
        v = 0;
      } else if (state == DayState.partial) {
        v = math.min(1, hist.entries[d]!.value / h.goal);
      }
      if (v != null) s += (v - s) / 20;
    }
  }
  return (s * 100).round();
}

/// Kept days this week, up to and including [today].
int weekCount(HabitModel h, HabitHistory hist,
        {required String today, required bool weekStartsSunday}) =>
    keptDaysInWeek(
        h, hist, weekStartOf(today, weekStartsSunday: weekStartsSunday),
        upTo: today);

/// Spare days still unused this week (0 for "a few times a week").
int sparesLeft(HabitModel h, HabitHistory hist,
    {required String today, required bool weekStartsSunday}) {
  if (h.schedule == HabitSchedule.perWeek || h.sparesPerWeek == 0) return 0;
  int misses = 0;
  for (String d = weekStartOf(today, weekStartsSunday: weekStartsSunday);
      d.compareTo(today) < 0;
      d = addDays(d, 1)) {
    final DayState s =
        dayState(h, hist, d, today: today, weekStartsSunday: weekStartsSunday);
    if (s == DayState.missed || s == DayState.partial) misses++;
  }
  return math.max(0, h.sparesPerWeek - misses);
}

/// Today's state and numbers for one habit.
HabitSummary summarize(HabitModel h, HabitHistory hist,
    {required String today, required bool weekStartsSunday}) {
  final HabitEntry? entry = hist.entries[today];
  return HabitSummary(
    today: dayState(h, hist, today,
        today: today, weekStartsSunday: weekStartsSunday),
    todayValue: entry?.status == EntryStatus.done ? entry!.value : 0,
    streak: currentStreak(h, hist,
        today: today, weekStartsSunday: weekStartsSunday),
    streakUnit: h.schedule == HabitSchedule.perWeek
        ? StreakUnit.weeks
        : StreakUnit.days,
    strengthPercent: strengthPercent(h, hist,
        today: today, weekStartsSunday: weekStartsSunday),
    weekCount:
        weekCount(h, hist, today: today, weekStartsSunday: weekStartsSunday),
    sparesLeft:
        sparesLeft(h, hist, today: today, weekStartsSunday: weekStartsSunday),
  );
}
