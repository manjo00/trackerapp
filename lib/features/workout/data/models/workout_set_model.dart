import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_set_model.freezed.dart';

/// Represents one logged set within a workout session.
@freezed
class WorkoutSetModel with _$WorkoutSetModel {
  const factory WorkoutSetModel({
    required int id,
    required int sessionId,
    int? exerciseId,
    required String exerciseName,
    required int setNumber,
    int? reps,
    double? weightKg,
    int? durationSeconds,
    int? restSeconds,
    int? rpe,
    @Default(false) bool isWarmup,
    @Default(false) bool isPr,
  }) = _WorkoutSetModel;
}
