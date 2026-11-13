import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/adhkar_progress.dart';
import '../domain/dhikr.dart';
import '../domain/habit_types.dart';
import 'models/habit_model.dart';
import 'repositories/habits_repository.dart';

/// Keeps one day's per-du'a counts of each du'a habit on the phone
/// (SharedPreferences), so leaving the counter halfway keeps the place.
/// Only the latest day is kept per habit; the habit's day value (how many
/// du'as were finished) lives in the database like any count habit's.
class AdhkarStore {
  AdhkarStore(this._prefs);

  final SharedPreferences _prefs;

  static String _key(int habitId) => 'adhkar_counts_$habitId';

  /// [habitId]'s counts for [day]; nothing counted when none were saved for
  /// that day, or the saved value can't be read.
  AdhkarProgress load(int habitId, String day, List<Dhikr> items) {
    final String? raw = _prefs.getString(_key(habitId));
    if (raw == null) return AdhkarProgress.empty(items);
    try {
      final Object? json = jsonDecode(raw);
      if (json is Map<String, dynamic> &&
          json['day'] == day &&
          json['counts'] is Map<String, dynamic>) {
        return AdhkarProgress.fromJson(
            items, json['counts'] as Map<String, dynamic>);
      }
    } on FormatException {
      // A damaged value reads as nothing counted.
    }
    return AdhkarProgress.empty(items);
  }

  /// Saves [progress] as [habitId]'s counts for [day].
  Future<void> save(int habitId, String day, AdhkarProgress progress) =>
      _prefs.setString(
          _key(habitId), jsonEncode({'day': day, 'counts': progress.toJson()}));
}

/// What the du'a counter does: read today's counts, and save each change.
class AdhkarActions {
  AdhkarActions(this._repo, this._store);

  final HabitsRepository _repo;
  final AdhkarStore _store;

  /// [habitId]'s saved counts for [day].
  AdhkarProgress load(int habitId, String day, List<Dhikr> items) =>
      _store.load(habitId, day, items);

  /// [habit]'s counts for [day] as the counter shows them: the saved ones,
  /// or every du'a done when the database already has the day kept.
  Future<AdhkarProgress> open(HabitModel habit, String day) async {
    final List<Dhikr> items =
        AdhkarList.fromSource(habit.autoSource)?.items ?? const [];
    final AdhkarProgress saved = _store.load(habit.id, day, items);
    final HabitEntry? entry =
        (await _repo.watchHistorySince(day).first).of(habit.id).entries[day];
    final bool kept = entry != null &&
        entry.status == EntryStatus.done &&
        entry.value >= items.length;
    return saved.shown(dayKept: kept);
  }

  /// Saves [after] for [day]. When the number of finished du'as changed, the
  /// habit's day value follows it (0 removes the day), so the habit is
  /// partial, kept, streaked and spared by the same rules as any count habit.
  Future<void> save(HabitModel habit, String day, AdhkarProgress before,
      AdhkarProgress after) async {
    await _store.save(habit.id, day, after);
    if (after.finished != before.finished) {
      await _repo.setValue(habit.id, day, after.finished);
    }
  }
}
