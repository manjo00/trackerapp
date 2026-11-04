import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/habit_types.dart';

// build_runner writes this file — never edit it manually.
part 'habit_model.freezed.dart';

/// Immutable domain representation of a single habit.
///
/// This is what the UI layer works with.  It is produced by the repository
/// from a raw Drift [Habit] row and is entirely independent of the database.
///
/// [freezed] generates:
///   - `copyWith(...)` — returns a new object with some fields changed
///   - `operator ==` and `hashCode` based on all fields
///   - `toString()` for easy debugging
@freezed
abstract class HabitModel with _$HabitModel {
  const factory HabitModel({
    required int id,
    required String name,
    required DateTime createdAt,

    /// The old "days a week" target; leaves with the old editor (demo 1,
    /// Task 7). New code reads [schedule] and [perWeek].
    @Default(7) int targetPerWeek,

    /// Whether a daily reminder notification is scheduled for this habit.
    @Default(false) bool reminderEnabled,

    /// Time-of-day for the reminder as "HH:mm", e.g. "07:00".
    /// Null means no time has been configured yet.
    String? reminderTime,

    /// A tick, or a count with a daily [goal] in [unit]s, + adding [step].
    @Default(HabitKind.tick) HabitKind kind,
    @Default(1) int goal,
    String? unit,
    @Default(1) int step,

    /// A Material icon name from the editor's list, and a palette index.
    @Default('check_circle') String icon,
    @Default(0) int color,

    /// When it is due: every day, the [weekdayMask] days (Monday bit 1 …
    /// Sunday bit 64), [perWeek] days a week, or by shift ([shiftMask]: day
    /// off 1, day shift 2, night shift 4).
    @Default(HabitSchedule.daily) HabitSchedule schedule,
    @Default(127) int weekdayMask,
    int? perWeek,
    @Default(7) int shiftMask,

    /// Spare days a week: a missed day uses one and the streak lives on.
    @Default(0) int sparesPerWeek,

    /// Where it is listed, its "After I …" cue, and its order there.
    @Default(HabitSection.any) HabitSection section,
    String? cue,
    @Default(0) int sortOrder,

    /// 'workout' when it ticks itself from logged workouts (demo 3).
    String? autoSource,
  }) = _HabitModel;
}
