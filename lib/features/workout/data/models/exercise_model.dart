import 'package:freezed_annotation/freezed_annotation.dart';
import 'muscle_group.dart';

part 'exercise_model.freezed.dart';

/// An entry in the exercise library — either seeded or user-created.
@freezed
class ExerciseModel with _$ExerciseModel {
  const ExerciseModel._();

  const factory ExerciseModel({
    required int id,
    required String name,
    required String primaryMuscle,
    String? secondaryMuscles,
    required String equipment,
    @Default(false) bool isCustom,
  }) = _ExerciseModel;

  /// Convenience accessor for the typed [MuscleGroup] enum.
  MuscleGroup get muscleGroup => MuscleGroup.fromString(primaryMuscle);

  /// Secondary muscle names split into a list.
  List<String> get secondaryMuscleList =>
      secondaryMuscles?.split(',').map((s) => s.trim()).toList() ?? [];
}
