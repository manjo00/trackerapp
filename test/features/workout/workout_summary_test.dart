import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/workout/data/models/workout_session_model.dart';
import 'package:life_tracker/features/workout/data/models/workout_set_model.dart';
import 'package:life_tracker/features/workout/domain/workout_summary.dart';

/// The numbers the workout history shows (look B, Ahmed's pick 2026-11-04):
/// kilos lifted, sets, records, the order the exercises were done in, and how
/// each exercise changed since the last workout of the same plan.
void main() {
  int nextId = 0;
  WorkoutSetModel set(String name, double? kg, int? reps,
          {bool pr = false, bool warmup = false, DateTime? tick}) =>
      WorkoutSetModel(
        id: ++nextId,
        sessionId: 1,
        exerciseName: name,
        setNumber: 1,
        weightKg: kg,
        reps: reps,
        isPr: pr,
        isWarmup: warmup,
        completedAt: tick,
      );
  WorkoutSessionModel workout(int id,
          {int? plan,
          String? name,
          DateTime? finishedAt,
          List<String> exercises = const ['Row', 'Press', 'Curl', 'Squat']}) =>
      WorkoutSessionModel(
        id: id,
        name: name,
        date: '2026-11-03',
        createdAt: DateTime(2026, 11, 3, 12, 49),
        programSessionId: plan,
        finishedAt: finishedAt,
        sets: [for (final String e in exercises) set(e, 40, 8)],
      );

  group('totals', () {
    test('kg lifted adds weight × reps, leaving out warm-ups and half-filled sets',
        () {
      expect(
        kgLifted([
          set('Leg Press', 70, 8),
          set('Leg Press', 80, 8),
          set('Leg Press', 20, 10, warmup: true),
          set('Row', 50, null),
        ]),
        1200,
      );
    });

    test('a set counts once its weight or reps are filled in', () {
      expect(
        loggedSetCount([
          set('Plank', null, 30),
          set('Row', 50, null),
          set('Row', null, null),
        ]),
        2,
      );
    });

    test('records count exercises, not sets', () {
      expect(
        recordCount([
          set('Leg Press', 70, 8, pr: true),
          set('Leg Press', 80, 8, pr: true),
          set('Leg Curl', 50, 7, pr: true),
          set('Row', 45, 8),
        ]),
        2,
      );
    });
  });

  test('ticked exercises go by their first tick, the rest keep the opened order',
      () {
    expect(
      exercisesInDoneOrder([
        (name: 'Row', tick: null),
        (name: 'Pulldown', tick: DateTime(2026, 11, 3, 13, 10)),
        (name: 'Curl', tick: null),
        (name: 'Squat', tick: DateTime(2026, 11, 3, 13, 0)),
        (name: 'Pulldown', tick: DateTime(2026, 11, 3, 12, 55)),
      ]),
      ['Pulldown', 'Squat', 'Row', 'Curl'],
    );
  });

  group('since last time', () {
    test('the previous workout is the next older one of the same plan', () {
      final List<WorkoutSessionModel> newestFirst = [
        workout(77, plan: 8, name: 'Push'),
        workout(69, plan: 9, name: 'Pull'),
        workout(71, plan: 8, name: 'Push'),
      ];
      expect(previousOfSamePlan(newestFirst, newestFirst[0])?.id, 71);
      expect(previousOfSamePlan(newestFirst, newestFirst[2]), isNull);
    });

    test('a short or half-done workout is skipped as "last time"', () {
      final List<WorkoutSessionModel> newestFirst = [
        workout(77, plan: 8),
        workout(68, plan: 8, exercises: ['Row']),
        workout(65, plan: 8, exercises: ['Row', 'Press', 'Curl']),
      ];
      expect(previousOfSamePlan(newestFirst, newestFirst[0])?.id, 65);
    });

    test('with nothing similar enough there is no "last time"', () {
      final List<WorkoutSessionModel> newestFirst = [
        workout(77, plan: 8),
        workout(68, plan: 8, exercises: ['Row', 'Lunge']),
      ];
      expect(previousOfSamePlan(newestFirst, newestFirst[0]), isNull);
    });

    test('a workout without a plan is compared by its name', () {
      final List<WorkoutSessionModel> newestFirst = [
        workout(5, name: 'Arms'),
        workout(4, name: 'Legs'),
        workout(3, name: 'Arms'),
      ];
      expect(previousOfSamePlan(newestFirst, newestFirst[0])?.id, 3);
    });

    test('an exercise is judged by its heaviest set, then the most reps', () {
      expect(
        topSet([
          set('Row', 25, 10),
          set('Row', 45, 6),
          set('Row', 45, 8),
          set('Row', 60, 2, warmup: true),
        ])?.reps,
        8,
      );
    });

    test('the change says what moved, in a few words', () {
      ({String label, bool better}) change(
              double? kgNow, int? repsNow, double? kgBefore, int? repsBefore) =>
          changeSinceLastTime(set('X', kgNow, repsNow),
              kgBefore == null && repsBefore == null
                  ? null
                  : set('X', kgBefore, repsBefore));
      expect(change(35, 6, 32.5, 6), (label: '+2.5 kg', better: true));
      expect(change(45, 8, 45, 6), (label: '+2 reps', better: true));
      expect(change(20, 9, 20, 8), (label: '+1 rep', better: true));
      expect(change(75, 5, 70, 8),
          (label: '+5 kg, 3 fewer reps', better: false));
      expect(change(30, 8, 30, 8), (label: 'same as last time', better: false));
      expect(change(40, 9, 42.5, 8),
          (label: '−2.5 kg, 1 more rep', better: false));
      expect(change(80, 8, null, null), (label: 'new', better: false));
    });

    test('the kg change is a whole percent, or nothing to compare with', () {
      expect(percentChange(5712, 5135), 11);
      expect(percentChange(4700, 5135), -8);
      expect(percentChange(5712, 0), isNull);
    });
  });

  group('labels', () {
    test('a set reads weight × reps, or whichever was filled in', () {
      expect(setLabel(set('Shoulder Press', 17.5, 8)), '17.5 × 8');
      expect(setLabel(set('Leg Press', 80, 8)), '80 × 8');
      expect(setLabel(set('Push-up', null, 12)), '12 reps');
      expect(setLabel(set('Row', 50, null)), '50 kg');
    });

    test('the row shows thousands as k, with two decimals at most', () {
      expect(shortKgNumber(5712.5), '5.71k');
      expect(shortKgNumber(7710), '7.71k');
      expect(shortKgNumber(10500), '10.5k');
      expect(shortKgNumber(2000), '2k');
      expect(shortKgNumber(850), '850');
    });

    test('the page shows every kilo', () {
      expect(fullKg(5712), '5,712 kg');
    });

    test('the length shows once the workout was finished', () {
      expect(lengthLabel(workout(1)), isNull);
      expect(
          lengthLabel(
              workout(1, finishedAt: DateTime(2026, 11, 3, 13, 41))),
          '52 min');
      expect(
          lengthLabel(
              workout(1, finishedAt: DateTime(2026, 11, 3, 14, 54))),
          '2 h 05 min');
    });

    test('a workout left open for hours has no length', () {
      expect(
          lengthLabel(workout(1, finishedAt: DateTime(2026, 11, 4, 9))),
          isNull);
    });
  });
}
