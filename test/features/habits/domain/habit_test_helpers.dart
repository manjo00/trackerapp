import 'package:life_tracker/features/habits/data/models/habit_model.dart';
import 'package:life_tracker/features/habits/domain/habit_day.dart';
import 'package:life_tracker/features/habits/domain/habit_types.dart';

/// "Today" in the rules tests: Wednesday 4 November 2026.
const String kToday = '2026-11-04';

/// A habit for the rules tests; created 1 October 2026 unless told otherwise.
HabitModel testHabit({
  HabitKind kind = HabitKind.tick,
  int goal = 1,
  HabitSchedule schedule = HabitSchedule.daily,
  int weekdayMask = 127,
  int? perWeek,
  int sparesPerWeek = 0,
  DateTime? createdAt,
}) =>
    HabitModel(
      id: 1,
      name: 'Test',
      createdAt: createdAt ?? DateTime(2026, 10, 1, 10),
      kind: kind,
      goal: goal,
      schedule: schedule,
      weekdayMask: weekdayMask,
      perWeek: perWeek,
      sparesPerWeek: sparesPerWeek,
    );

/// A history from day → value (a tick is 1), plus rest/sick days and pauses.
HabitHistory testHistory(
  Map<String, int> values, {
  Map<String, EntryStatus> breaks = const {},
  List<PauseRange> pauses = const [],
}) =>
    HabitHistory(
      entries: {
        for (final MapEntry<String, int> e in values.entries)
          e.key: HabitEntry(e.value),
        for (final MapEntry<String, EntryStatus> b in breaks.entries)
          b.key: HabitEntry(0, b.value),
      },
      pauses: pauses,
    );

/// One tick on every day from [from] to [to], both included, except [except].
Map<String, int> ticksFrom(String from, String to,
    {Set<String> except = const {}, int value = 1}) {
  final Map<String, int> out = {};
  for (String d = from; d.compareTo(to) <= 0; d = addDays(d, 1)) {
    if (!except.contains(d)) out[d] = value;
  }
  return out;
}
