import 'package:drift/drift.dart';

/// The built-in + user-created exercise library.
///
/// Each row is one exercise (e.g. "Bench Press").  The [primaryMuscle] and
/// [equipment] fields drive the muscle-group filter chips in the picker screen.
/// [isCustom] = false for seeded exercises, true for user-added ones.
class ExerciseLibrary extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Display name of the exercise, e.g. "Bench Press".
  TextColumn get name => text().withLength(min: 1, max: 150)();

  /// Primary muscle group targeted (e.g. "Chest", "Back", "Legs",
  /// "Core", "Shoulders", "Arms").
  TextColumn get primaryMuscle => text()();

  /// Comma-separated secondary muscles, e.g. "Triceps,Shoulders".
  /// NULL if there are no notable secondary muscles.
  TextColumn get secondaryMuscles => text().nullable()();

  /// Equipment category: "Barbell", "Dumbbell", "Machine",
  /// "Bodyweight", "Cable", "Kettlebell", "Other".
  TextColumn get equipment => text()();

  /// False for seeded (built-in) exercises; true for user-added.
  BoolColumn get isCustom =>
      boolean().withDefault(const Constant(false))();
}
