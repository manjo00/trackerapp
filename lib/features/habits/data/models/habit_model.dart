import 'package:freezed_annotation/freezed_annotation.dart';

// build_runner writes these two files — never edit them manually.
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
    required int targetPerWeek,
  }) = _HabitModel;
}
