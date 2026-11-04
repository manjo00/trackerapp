import 'package:life_tracker/features/workout/data/models/workout_session_model.dart';
import 'package:life_tracker/features/workout/data/models/workout_set_model.dart';

/// Two Push workouts for the history row and page tests: today's (4 sets,
/// 1,910 kg, records on Leg Press and Leg Curl, Leg Press ticked first) and the
/// one before it (1,275 kg).
WorkoutSetModel historySet(int id, int session, String name, double kg, int reps,
        {bool pr = false, DateTime? tick}) =>
    WorkoutSetModel(
      id: id,
      sessionId: session,
      exerciseName: name,
      setNumber: 1,
      weightKg: kg,
      reps: reps,
      isPr: pr,
      completedAt: tick,
    );

final WorkoutSessionModel pushToday = WorkoutSessionModel(
  id: 77,
  name: 'Push',
  date: '2026-11-03',
  createdAt: DateTime(2026, 11, 3, 12, 49),
  finishedAt: DateTime(2026, 11, 3, 13, 41),
  programSessionId: 8,
  sets: [
    historySet(1, 77, 'Row', 45, 8),
    historySet(2, 77, 'Leg Press', 70, 8, tick: DateTime(2026, 11, 3, 12, 55)),
    historySet(3, 77, 'Leg Press', 80, 8,
        pr: true, tick: DateTime(2026, 11, 3, 12, 58)),
    historySet(4, 77, 'Leg Curl', 50, 7,
        pr: true, tick: DateTime(2026, 11, 3, 13, 5)),
  ],
);

final WorkoutSessionModel pushBefore = WorkoutSessionModel(
  id: 71,
  name: 'Push',
  date: '2026-10-31',
  createdAt: DateTime(2026, 10, 31, 9, 41),
  programSessionId: 8,
  sets: [
    historySet(11, 71, 'Leg Press', 75, 8),
    historySet(12, 71, 'Row', 45, 6),
    historySet(13, 71, 'Leg Curl', 45, 9),
  ],
);
