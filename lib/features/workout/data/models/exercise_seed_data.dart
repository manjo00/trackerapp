/// Pre-seeded exercise library entries.
///
/// Each map must have keys: name, primaryMuscle, secondaryMuscles (nullable),
/// equipment.  These are inserted once during the DB v4 migration and when
/// the database is first created.
const List<Map<String, String?>> kSeedExercises = [
  // ── Chest ─────────────────────────────────────────────────────────────────
  {'name': 'Bench Press',          'primaryMuscle': 'Chest',     'secondaryMuscles': 'Triceps,Shoulders', 'equipment': 'Barbell'},
  {'name': 'Incline Bench Press',  'primaryMuscle': 'Chest',     'secondaryMuscles': 'Triceps,Shoulders', 'equipment': 'Barbell'},
  {'name': 'Dumbbell Fly',         'primaryMuscle': 'Chest',     'secondaryMuscles': 'Shoulders',         'equipment': 'Dumbbell'},
  {'name': 'Cable Fly',            'primaryMuscle': 'Chest',     'secondaryMuscles': 'Shoulders',         'equipment': 'Cable'},
  {'name': 'Push-up',              'primaryMuscle': 'Chest',     'secondaryMuscles': 'Triceps,Core',      'equipment': 'Bodyweight'},
  {'name': 'Dips',                 'primaryMuscle': 'Chest',     'secondaryMuscles': 'Triceps,Shoulders', 'equipment': 'Bodyweight'},

  // ── Back ──────────────────────────────────────────────────────────────────
  {'name': 'Deadlift',             'primaryMuscle': 'Back',      'secondaryMuscles': 'Legs,Core',         'equipment': 'Barbell'},
  {'name': 'Pull-up',              'primaryMuscle': 'Back',      'secondaryMuscles': 'Biceps',            'equipment': 'Bodyweight'},
  {'name': 'Chin-up',              'primaryMuscle': 'Back',      'secondaryMuscles': 'Biceps',            'equipment': 'Bodyweight'},
  {'name': 'Barbell Row',          'primaryMuscle': 'Back',      'secondaryMuscles': 'Biceps,Core',       'equipment': 'Barbell'},
  {'name': 'Seated Cable Row',     'primaryMuscle': 'Back',      'secondaryMuscles': 'Biceps',            'equipment': 'Cable'},
  {'name': 'Lat Pulldown',         'primaryMuscle': 'Back',      'secondaryMuscles': 'Biceps',            'equipment': 'Cable'},
  {'name': 'Dumbbell Row',         'primaryMuscle': 'Back',      'secondaryMuscles': 'Biceps',            'equipment': 'Dumbbell'},
  {'name': 'T-Bar Row',            'primaryMuscle': 'Back',      'secondaryMuscles': 'Biceps,Core',       'equipment': 'Barbell'},

  // ── Legs ──────────────────────────────────────────────────────────────────
  {'name': 'Squat',                'primaryMuscle': 'Legs',      'secondaryMuscles': 'Core,Glutes',       'equipment': 'Barbell'},
  {'name': 'Front Squat',          'primaryMuscle': 'Legs',      'secondaryMuscles': 'Core',              'equipment': 'Barbell'},
  {'name': 'Romanian Deadlift',    'primaryMuscle': 'Legs',      'secondaryMuscles': 'Glutes,Back',       'equipment': 'Barbell'},
  {'name': 'Leg Press',            'primaryMuscle': 'Legs',      'secondaryMuscles': 'Glutes',            'equipment': 'Machine'},
  {'name': 'Leg Curl',             'primaryMuscle': 'Legs',      'secondaryMuscles': null,                'equipment': 'Machine'},
  {'name': 'Leg Extension',        'primaryMuscle': 'Legs',      'secondaryMuscles': null,                'equipment': 'Machine'},
  {'name': 'Lunges',               'primaryMuscle': 'Legs',      'secondaryMuscles': 'Glutes,Core',       'equipment': 'Bodyweight'},
  {'name': 'Bulgarian Split Squat','primaryMuscle': 'Legs',      'secondaryMuscles': 'Glutes',            'equipment': 'Dumbbell'},
  {'name': 'Calf Raise',           'primaryMuscle': 'Legs',      'secondaryMuscles': null,                'equipment': 'Machine'},
  {'name': 'Hip Thrust',           'primaryMuscle': 'Legs',      'secondaryMuscles': 'Glutes',            'equipment': 'Barbell'},

  // ── Shoulders ─────────────────────────────────────────────────────────────
  {'name': 'Overhead Press',       'primaryMuscle': 'Shoulders', 'secondaryMuscles': 'Triceps,Core',      'equipment': 'Barbell'},
  {'name': 'Dumbbell Shoulder Press','primaryMuscle':'Shoulders','secondaryMuscles': 'Triceps',           'equipment': 'Dumbbell'},
  {'name': 'Lateral Raise',        'primaryMuscle': 'Shoulders', 'secondaryMuscles': null,                'equipment': 'Dumbbell'},
  {'name': 'Front Raise',          'primaryMuscle': 'Shoulders', 'secondaryMuscles': null,                'equipment': 'Dumbbell'},
  {'name': 'Face Pull',            'primaryMuscle': 'Shoulders', 'secondaryMuscles': 'Back',              'equipment': 'Cable'},
  {'name': 'Arnold Press',         'primaryMuscle': 'Shoulders', 'secondaryMuscles': 'Triceps',           'equipment': 'Dumbbell'},

  // ── Arms ──────────────────────────────────────────────────────────────────
  {'name': 'Barbell Curl',         'primaryMuscle': 'Arms',      'secondaryMuscles': null,                'equipment': 'Barbell'},
  {'name': 'Dumbbell Curl',        'primaryMuscle': 'Arms',      'secondaryMuscles': null,                'equipment': 'Dumbbell'},
  {'name': 'Hammer Curl',          'primaryMuscle': 'Arms',      'secondaryMuscles': null,                'equipment': 'Dumbbell'},
  {'name': 'Tricep Pushdown',      'primaryMuscle': 'Arms',      'secondaryMuscles': null,                'equipment': 'Cable'},
  {'name': 'Skull Crusher',        'primaryMuscle': 'Arms',      'secondaryMuscles': null,                'equipment': 'Barbell'},
  {'name': 'Overhead Tricep Extension','primaryMuscle':'Arms',   'secondaryMuscles': null,                'equipment': 'Dumbbell'},
  {'name': 'Preacher Curl',        'primaryMuscle': 'Arms',      'secondaryMuscles': null,                'equipment': 'Barbell'},

  // ── Core ──────────────────────────────────────────────────────────────────
  {'name': 'Plank',                'primaryMuscle': 'Core',      'secondaryMuscles': 'Shoulders',         'equipment': 'Bodyweight'},
  {'name': 'Crunch',               'primaryMuscle': 'Core',      'secondaryMuscles': null,                'equipment': 'Bodyweight'},
  {'name': 'Cable Crunch',         'primaryMuscle': 'Core',      'secondaryMuscles': null,                'equipment': 'Cable'},
  {'name': 'Leg Raise',            'primaryMuscle': 'Core',      'secondaryMuscles': null,                'equipment': 'Bodyweight'},
  {'name': 'Russian Twist',        'primaryMuscle': 'Core',      'secondaryMuscles': null,                'equipment': 'Bodyweight'},
  {'name': 'Ab Wheel Rollout',     'primaryMuscle': 'Core',      'secondaryMuscles': 'Shoulders',         'equipment': 'Other'},
];
