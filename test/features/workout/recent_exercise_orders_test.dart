import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/workout/data/dao/workout_dao.dart';

/// The smart order learns from the order exercises were really done in. The
/// app makes an exercise's set rows when it's opened, so the first filled set
/// of each exercise gives its place.
void main() {
  late AppDatabase db;
  late WorkoutDao dao;
  late int fullBody;
  late int otherDay;
  int day = 0;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = WorkoutDao(db);
    day = 0;
    final int program = await db.into(db.programs).insert(
        ProgramsCompanion.insert(name: 'Mine', createdAt: DateTime(2026, 10)));
    fullBody = await db.into(db.programSessions).insert(
        ProgramSessionsCompanion.insert(programId: program, name: 'Full body'));
    otherDay = await db.into(db.programSessions).insert(
        ProgramSessionsCompanion.insert(programId: program, name: 'Other'));
  });
  tearDown(() async => db.close());

  /// Logs one workout of [programSessionId], a day after the last one. Each
  /// entry is an exercise and whether its set was filled in; the rows go in
  /// the order given.
  Future<void> workout(int programSessionId, List<(String, bool)> sets) async {
    day++;
    final int session = await dao.insertSession(WorkoutSessionsCompanion.insert(
      date: '2026-10-${day.toString().padLeft(2, '0')}',
      createdAt: DateTime(2026, 10, day),
      programSessionId: Value(programSessionId),
    ));
    int setNumber = 0;
    for (final (String name, bool filled) in sets) {
      await dao.insertSet(WorkoutSetsCompanion.insert(
        sessionId: session,
        exerciseName: name,
        setNumber: ++setNumber,
        reps: Value(filled ? 8 : null),
        weightKg: Value(filled ? 40.0 : null),
      ));
    }
  }

  test('reads the order exercises were done in, newest workout first',
      () async {
    await workout(fullBody, [('Row', true), ('Pulldown', true)]);
    await workout(fullBody, [
      ('Pulldown', true),
      ('Row', true),
      ('Pulldown', true),
      ('Curl', true),
    ]);
    expect(await dao.recentExerciseOrders(fullBody), [
      ['Pulldown', 'Row', 'Curl'],
      ['Row', 'Pulldown'],
    ]);
  });

  test('an exercise opened but never filled in has no place', () async {
    await workout(fullBody, [('Leg press', false), ('Row', true)]);
    expect(await dao.recentExerciseOrders(fullBody), [
      ['Row'],
    ]);
  });

  test('a workout with nothing filled in does not count', () async {
    await workout(fullBody, [('Row', true)]);
    await workout(fullBody, [('Pulldown', false)]);
    expect(await dao.recentExerciseOrders(fullBody), [
      ['Row'],
    ]);
  });

  test('only workouts of the same planned workout count', () async {
    await workout(fullBody, [('Row', true)]);
    await workout(otherDay, [('Squat', true)]);
    expect(await dao.recentExerciseOrders(fullBody), [
      ['Row'],
    ]);
  });

  test('reads at most three workouts', () async {
    await workout(fullBody, [('A', true)]);
    await workout(fullBody, [('B', true)]);
    await workout(fullBody, [('C', true)]);
    await workout(fullBody, [('D', true)]);
    expect(await dao.recentExerciseOrders(fullBody), [
      ['D'],
      ['C'],
      ['B'],
    ]);
  });
}
