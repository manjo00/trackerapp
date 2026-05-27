import 'package:freezed_annotation/freezed_annotation.dart';

part 'program_exercise_model.freezed.dart';

/// An exercise slot within a program session type.
@freezed
class ProgramExerciseModel with _$ProgramExerciseModel {
  const ProgramExerciseModel._();

  const factory ProgramExerciseModel({
    required int id,
    required int programSessionId,
    int? exerciseId,
    required String exerciseName,
    @Default(3) int targetSets,
    @Default(10) int targetReps,

    /// Rest between sets in seconds (default 2 min = 120 s).
    @Default(120) int restSeconds,
    @Default(0) int orderIndex,
  }) = _ProgramExerciseModel;

  /// Human-readable rest label, e.g. "2:00" or "1:30".
  String get restLabel {
    final m = restSeconds ~/ 60;
    final s = (restSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Summary string shown in the session overview, e.g. "3 × 10".
  String get volumeLabel => '$targetSets × $targetReps';
}
