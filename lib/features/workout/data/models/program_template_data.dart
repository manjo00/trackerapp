/// Data classes used to define built-in program templates.
///
/// Templates are pure Dart objects — they are converted into real database
/// rows by [ProgramRepository.createFromTemplate].
class ProgramTemplateData {
  const ProgramTemplateData({
    required this.name,
    required this.description,
    required this.splitType,
    required this.sessions,
  });

  final String name;
  final String description;
  final String splitType; // 'rotating' | 'weekly'
  final List<SessionTemplateData> sessions;
}

class SessionTemplateData {
  const SessionTemplateData({
    required this.name,
    required this.colorValue,
    required this.orderIndex,
    this.weekDays,
    required this.exercises,
  });

  final String name;
  final int colorValue;
  final int orderIndex;

  /// For weekly splits: ISO weekday CSV (e.g. "1,4" = Mon + Thu).
  final String? weekDays;

  final List<ExerciseTemplateData> exercises;
}

class ExerciseTemplateData {
  const ExerciseTemplateData({
    required this.exerciseName,
    required this.targetSets,
    required this.targetReps,
    required this.restSeconds,
  });

  final String exerciseName;
  final int targetSets;
  final int targetReps;
  final int restSeconds;
}

// ── Built-in templates ────────────────────────────────────────────────────────

/// Push / Pull / Legs — 6-day rotating split.
///
/// One of the most popular hypertrophy programs online.  You cycle through
/// Push → Pull → Legs repeatedly, typically resting on day 7.
const ProgramTemplateData kTemplatePPL = ProgramTemplateData(
  name: 'Push / Pull / Legs',
  description:
      'Classic 6-day rotating split. Cycle Push → Pull → Legs, rest on day 7.',
  splitType: 'rotating',
  sessions: [
    SessionTemplateData(
      name: 'Push',
      colorValue: 0xFFE53935, // red
      orderIndex: 0,
      exercises: [
        ExerciseTemplateData(
            exerciseName: 'Bench Press',
            targetSets: 4,
            targetReps: 8,
            restSeconds: 180),
        ExerciseTemplateData(
            exerciseName: 'Overhead Press',
            targetSets: 3,
            targetReps: 10,
            restSeconds: 150),
        ExerciseTemplateData(
            exerciseName: 'Incline Dumbbell Press',
            targetSets: 3,
            targetReps: 12,
            restSeconds: 120),
        ExerciseTemplateData(
            exerciseName: 'Lateral Raise',
            targetSets: 3,
            targetReps: 15,
            restSeconds: 60),
        ExerciseTemplateData(
            exerciseName: 'Tricep Pushdown',
            targetSets: 3,
            targetReps: 15,
            restSeconds: 60),
      ],
    ),
    SessionTemplateData(
      name: 'Pull',
      colorValue: 0xFF1E88E5, // blue
      orderIndex: 1,
      exercises: [
        ExerciseTemplateData(
            exerciseName: 'Barbell Row',
            targetSets: 4,
            targetReps: 8,
            restSeconds: 180),
        ExerciseTemplateData(
            exerciseName: 'Lat Pulldown',
            targetSets: 3,
            targetReps: 10,
            restSeconds: 120),
        ExerciseTemplateData(
            exerciseName: 'Seated Cable Row',
            targetSets: 3,
            targetReps: 12,
            restSeconds: 120),
        ExerciseTemplateData(
            exerciseName: 'Bicep Curl',
            targetSets: 3,
            targetReps: 12,
            restSeconds: 60),
        ExerciseTemplateData(
            exerciseName: 'Face Pull',
            targetSets: 3,
            targetReps: 20,
            restSeconds: 60),
      ],
    ),
    SessionTemplateData(
      name: 'Legs',
      colorValue: 0xFF43A047, // green
      orderIndex: 2,
      exercises: [
        ExerciseTemplateData(
            exerciseName: 'Squat',
            targetSets: 4,
            targetReps: 8,
            restSeconds: 240),
        ExerciseTemplateData(
            exerciseName: 'Romanian Deadlift',
            targetSets: 3,
            targetReps: 10,
            restSeconds: 180),
        ExerciseTemplateData(
            exerciseName: 'Leg Press',
            targetSets: 3,
            targetReps: 12,
            restSeconds: 150),
        ExerciseTemplateData(
            exerciseName: 'Leg Curl',
            targetSets: 3,
            targetReps: 12,
            restSeconds: 90),
        ExerciseTemplateData(
            exerciseName: 'Calf Raise',
            targetSets: 4,
            targetReps: 20,
            restSeconds: 60),
      ],
    ),
  ],
);

/// Upper / Lower Split — 4-day weekly split (Mon/Thu Upper, Tue/Fri Lower).
///
/// Balances frequency with recovery.  Great for intermediates.
const ProgramTemplateData kTemplateUpperLower = ProgramTemplateData(
  name: 'Upper / Lower Split',
  description:
      'Train 4 days/week. Upper body Mon+Thu, Lower body Tue+Fri.',
  splitType: 'weekly',
  sessions: [
    SessionTemplateData(
      name: 'Upper Body',
      colorValue: 0xFF8E24AA, // purple
      orderIndex: 0,
      weekDays: '1,4', // Monday + Thursday
      exercises: [
        ExerciseTemplateData(
            exerciseName: 'Bench Press',
            targetSets: 4,
            targetReps: 8,
            restSeconds: 180),
        ExerciseTemplateData(
            exerciseName: 'Barbell Row',
            targetSets: 4,
            targetReps: 8,
            restSeconds: 180),
        ExerciseTemplateData(
            exerciseName: 'Overhead Press',
            targetSets: 3,
            targetReps: 10,
            restSeconds: 150),
        ExerciseTemplateData(
            exerciseName: 'Lat Pulldown',
            targetSets: 3,
            targetReps: 10,
            restSeconds: 120),
        ExerciseTemplateData(
            exerciseName: 'Bicep Curl',
            targetSets: 3,
            targetReps: 12,
            restSeconds: 60),
        ExerciseTemplateData(
            exerciseName: 'Skull Crusher',
            targetSets: 3,
            targetReps: 12,
            restSeconds: 60),
      ],
    ),
    SessionTemplateData(
      name: 'Lower Body',
      colorValue: 0xFFF57C00, // orange
      orderIndex: 1,
      weekDays: '2,5', // Tuesday + Friday
      exercises: [
        ExerciseTemplateData(
            exerciseName: 'Squat',
            targetSets: 4,
            targetReps: 8,
            restSeconds: 240),
        ExerciseTemplateData(
            exerciseName: 'Romanian Deadlift',
            targetSets: 4,
            targetReps: 8,
            restSeconds: 180),
        ExerciseTemplateData(
            exerciseName: 'Leg Press',
            targetSets: 3,
            targetReps: 12,
            restSeconds: 150),
        ExerciseTemplateData(
            exerciseName: 'Leg Curl',
            targetSets: 3,
            targetReps: 12,
            restSeconds: 90),
        ExerciseTemplateData(
            exerciseName: 'Calf Raise',
            targetSets: 4,
            targetReps: 20,
            restSeconds: 60),
      ],
    ),
  ],
);

/// All built-in templates.
const List<ProgramTemplateData> kBuiltInProgramTemplates = [
  kTemplatePPL,
  kTemplateUpperLower,
];
