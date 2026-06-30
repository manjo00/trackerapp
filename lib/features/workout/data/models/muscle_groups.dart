/// The fixed set of trackable muscle groups and the mapping from an exercise's
/// muscle tag to its group.
///
/// Groups are push/pull-oriented (legs are folded into push & pull on the
/// training side, but still tracked as their own group here). A logged set is
/// credited to a group when the exercise's primary OR secondary muscle maps to
/// it — counted once per group, even if both muscles land in the same group.
class MuscleGroup {
  const MuscleGroup._();

  static const String push = 'push';
  static const String pull = 'pull';
  static const String legs = 'legs';
  static const String forearms = 'forearms';
  static const String core = 'core';

  /// All groups, in display order.
  static const List<String> all = [push, pull, legs, forearms, core];

  /// Human-readable labels.
  static const Map<String, String> labels = {
    push: 'Push',
    pull: 'Pull',
    legs: 'Legs',
    forearms: 'Forearms',
    core: 'Core',
  };

  /// Exercise muscle tag → group. Tags come from the exercise library
  /// (primaryMuscle / secondaryMuscles).
  static const Map<String, String> _byMuscle = {
    // Push
    'Chest': push,
    'Shoulders': push,
    'Triceps': push,
    // Pull
    'Back': pull,
    'Lats': pull,
    'Biceps': pull,
    // Forearms
    'Forearms': forearms,
    // Legs
    'Legs': legs,
    'Quads': legs,
    'Hamstrings': legs,
    'Glutes': legs,
    'Calves': legs,
    // Core
    'Core': core,
  };

  static String label(String groupKey) => labels[groupKey] ?? groupKey;

  /// The group for a single muscle tag, or null if unmapped.
  static String? forMuscle(String? muscle) =>
      muscle == null ? null : _byMuscle[muscle];

  /// All groups a set touches, given its primary + secondary (CSV) muscles.
  /// Returns a de-duplicated set so one set never double-counts a group.
  static Set<String> forExercise(String? primary, String? secondaryCsv) {
    final Set<String> groups = {};
    final String? p = forMuscle(primary);
    if (p != null) groups.add(p);
    if (secondaryCsv != null && secondaryCsv.isNotEmpty) {
      for (final String m in secondaryCsv.split(',')) {
        final String? g = forMuscle(m.trim());
        if (g != null) groups.add(g);
      }
    }
    return groups;
  }
}
