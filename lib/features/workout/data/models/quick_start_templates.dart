/// Freeform quick-start session templates — a starting exercise list you can
/// fire off on any free day, independent of a fixed program/rotation.
///
/// Legs are folded into Push (anterior: quads) and Pull (posterior: hams/glutes)
/// so there's no separate leg day. Everything is editable once the session
/// starts; these are just the opening line-up.
class QuickStartTemplate {
  const QuickStartTemplate({required this.name, required this.exercises});

  final String name;

  /// Exercise names — must match entries in the seeded exercise library.
  final List<String> exercises;
}

const List<QuickStartTemplate> kQuickStartTemplates = [
  QuickStartTemplate(
    name: 'Push',
    exercises: [
      'Bench Press',
      'Incline Bench Press',
      'Overhead Press',
      'Lateral Raise',
      'Tricep Pushdown',
      'Skull Crusher',
      'Leg Press', // anterior legs
      'Leg Extension',
    ],
  ),
  QuickStartTemplate(
    name: 'Pull',
    exercises: [
      'Barbell Row',
      'Lat Pulldown',
      'Seated Cable Row',
      'Face Pull',
      'Barbell Curl',
      'Hammer Curl',
      'Romanian Deadlift', // posterior legs
      'Leg Curl',
    ],
  ),
  QuickStartTemplate(
    name: 'Upper',
    exercises: [
      'Bench Press',
      'Barbell Row',
      'Overhead Press',
      'Lat Pulldown',
      'Lateral Raise',
      'Barbell Curl',
      'Tricep Pushdown',
    ],
  ),
  QuickStartTemplate(
    name: 'Full',
    exercises: [
      'Squat',
      'Bench Press',
      'Barbell Row',
      'Overhead Press',
      'Romanian Deadlift',
      'Barbell Curl',
      'Tricep Pushdown',
      'Plank',
    ],
  ),
];
