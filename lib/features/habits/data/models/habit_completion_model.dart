import 'package:freezed_annotation/freezed_annotation.dart';

part 'habit_completion_model.freezed.dart';

/// Immutable representation of one completion record.
///
/// [date] uses the format `"yyyy-MM-dd"` (e.g. `"2026-05-26"`) — the same
/// format used in the database.  Plain strings make streak arithmetic easy
/// and avoid timezone surprises.
@freezed
abstract class HabitCompletionModel with _$HabitCompletionModel {
  const factory HabitCompletionModel({
    required int id,
    required int habitId,
    required String date, // "yyyy-MM-dd"
  }) = _HabitCompletionModel;
}
