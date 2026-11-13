import 'package:shared_preferences/shared_preferences.dart';

import '../domain/adhkar_progress.dart';
import '../domain/habit_types.dart';
import 'models/habit_model.dart';
import 'repositories/habits_repository.dart';

/// Set once both du'a habits have been added, so one he deletes never comes
/// back.
const String kAdhkarHabitsAddedKey = 'adhkar_habits_added';

/// Adds the morning and night du'a habits Ahmed asked for (2026-11-13), once,
/// and keeps each one's goal equal to its list's length. Runs with the app's
/// launch work.
Future<void> ensureAdhkarHabits(HabitsRepository repo, SharedPreferences prefs,
    {DateTime? now}) async {
  final List<HabitModel> habits = await repo.getAllHabits();
  for (final HabitModel h in habits) {
    final AdhkarList? list = AdhkarList.fromSource(h.autoSource);
    if (list == null) continue;
    // A du'a habit is a count of its list's du'as; an edit that changed it
    // (or a list that grew) is put right here.
    if (h.kind != HabitKind.count || h.goal != list.items.length) {
      await repo.saveHabit(
          h.copyWith(kind: HabitKind.count, goal: list.items.length, step: 1));
    }
  }
  if (prefs.getBool(kAdhkarHabitsAddedKey) ?? false) return;

  final DateTime at = now ?? DateTime.now();
  for (final AdhkarList list in AdhkarList.values) {
    if (habits.any((HabitModel h) => h.autoSource == list.source)) continue;
    await repo.saveHabit(_habitFor(list, at));
  }
  await prefs.setBool(kAdhkarHabitsAddedKey, true);
}

HabitModel _habitFor(AdhkarList list, DateTime at) {
  final bool morning = list == AdhkarList.morning;
  return HabitModel(
    id: 0,
    name: morning ? "Morning du'as" : "Night du'as",
    createdAt: at,
    kind: HabitKind.count,
    goal: list.items.length,
    unit: "du'as",
    icon: morning ? 'wb_sunny' : 'bedtime',
    // Amber for the morning, indigo for the night (kHabitHues 45 and 252).
    color: morning ? 4 : 0,
    // One spare day a week, as the editor proposes for an every-day habit.
    sparesPerWeek: 1,
    section: morning ? HabitSection.wake : HabitSection.sleep,
    autoSource: list.source,
  );
}
