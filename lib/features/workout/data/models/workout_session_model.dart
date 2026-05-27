import 'package:freezed_annotation/freezed_annotation.dart';
import 'workout_set_model.dart';

part 'workout_session_model.freezed.dart';

/// A complete workout session with its sets pre-loaded.
@freezed
class WorkoutSessionModel with _$WorkoutSessionModel {
  const WorkoutSessionModel._();

  const factory WorkoutSessionModel({
    required int id,
    String? name,
    required String date,
    String? notes,
    required DateTime createdAt,

    /// NULL for freeform sessions; non-null when based on a program session type.
    int? programSessionId,

    @Default([]) List<WorkoutSetModel> sets,
  }) = _WorkoutSessionModel;

  /// Display title: user-given name or a generated label.
  String get displayName => name?.isNotEmpty == true ? name! : 'Workout';

  /// Unique exercise names performed in this session, in the order
  /// they first appear.
  List<String> get exerciseNames {
    final seen = <String>{};
    final names = <String>[];
    for (final s in sets) {
      if (seen.add(s.exerciseName)) names.add(s.exerciseName);
    }
    return names;
  }

  /// Sets grouped by exercise name, preserving insertion order.
  Map<String, List<WorkoutSetModel>> get setsByExercise {
    final map = <String, List<WorkoutSetModel>>{};
    for (final s in sets) {
      (map[s.exerciseName] ??= []).add(s);
    }
    return map;
  }

  /// Unique primary-muscle labels covered in this session.
  List<String> get musclesCovered {
    // We only know exercise names here; the muscle lookup happens in the UI
    // using the exercise library.  Return exercise names as fallback labels.
    return exerciseNames;
  }

  /// Total set count.
  int get totalSets => sets.length;

  /// Whether any set in this session is a PR.
  bool get hasPr => sets.any((s) => s.isPr);
}
