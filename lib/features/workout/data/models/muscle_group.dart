/// The muscle groups used for filtering and display in the workout feature.
enum MuscleGroup {
  all,
  chest,
  back,
  legs,
  shoulders,
  arms,
  core,
  glutes;

  String get label => switch (this) {
        MuscleGroup.all => 'All',
        MuscleGroup.chest => 'Chest',
        MuscleGroup.back => 'Back',
        MuscleGroup.legs => 'Legs',
        MuscleGroup.shoulders => 'Shoulders',
        MuscleGroup.arms => 'Arms',
        MuscleGroup.core => 'Core',
        MuscleGroup.glutes => 'Glutes',
      };

  /// Returns the [MuscleGroup] whose label matches [s] (case-insensitive).
  /// Falls back to [MuscleGroup.all] for unknown strings.
  static MuscleGroup fromString(String s) => MuscleGroup.values.firstWhere(
        (g) => g.label.toLowerCase() == s.toLowerCase(),
        orElse: () => MuscleGroup.all,
      );
}
