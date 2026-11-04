import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';

/// Opening a version-25 database (the schema before the workout log) runs the
/// v26 upgrade: every workout and set survives as it was, and the two new
/// columns (a set's tick time, a workout's finish time) start empty.
void main() {
  late AppDatabase db;

  setUp(() {
    final List<String> v25 = File('test/core/database/fixtures/schema_v25.sql')
        .readAsStringSync()
        .split(RegExp(r';\r?\n')) // a Windows checkout may add \r
        .where((String s) => s.trim().isNotEmpty)
        .toList();
    db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
      for (final String statement in v25) {
        raw.execute(statement);
      }
      // 3 Nov 2026 18:00 UTC, in seconds (drift's default date format).
      raw.execute('INSERT INTO workout_sessions (id, name, date, created_at) '
          "VALUES (77, 'Push', '2026-11-03', 1793728800)");
      raw.execute('INSERT INTO workout_sets (id, session_id, exercise_name, '
          'set_number, reps, weight_kg, is_warmup, is_pr) '
          "VALUES (500, 77, 'Leg Press', 1, 10, 120.0, 0, 1)");
      raw.execute('PRAGMA user_version = 25');
    }));
  });
  tearDown(() => db.close());

  Future<List<String>> columnsOf(String table) async => [
        for (final QueryRow row
            in await db.customSelect('PRAGMA table_info($table)').get())
          row.read<String>('name'),
      ];

  test('the upgrade lands on the current version', () async {
    final QueryRow row =
        await db.customSelect('PRAGMA user_version').getSingle();
    expect(row.read<int>('user_version'), db.schemaVersion);
  });

  test('workouts and sets survive the upgrade unchanged', () async {
    final WorkoutSession session =
        await db.select(db.workoutSessions).getSingle();
    expect((session.id, session.name, session.date), (77, 'Push', '2026-11-03'));
    expect(session.createdAt.isAtSameMomentAs(DateTime.utc(2026, 11, 3, 18)),
        isTrue);
    final WorkoutSet set = await db.select(db.workoutSets).getSingle();
    expect(
      (set.id, set.sessionId, set.exerciseName, set.reps, set.weightKg),
      (500, 77, 'Leg Press', 10, 120.0),
    );
    expect((set.isWarmup, set.isPr), (false, true));
  });

  test('the tick and finish times are new columns, empty for old rows',
      () async {
    expect(await columnsOf('workout_sets'), contains('completed_at'));
    expect(await columnsOf('workout_sessions'), contains('finished_at'));
    final QueryRow row = await db
        .customSelect('SELECT s.completed_at AS tick, w.finished_at AS done '
            'FROM workout_sets s JOIN workout_sessions w ON w.id = s.session_id')
        .getSingle();
    expect(row.read<int?>('tick'), isNull);
    expect(row.read<int?>('done'), isNull);
  });

  test('a backup made before v26 still restores, with no times', () {
    // The backup restores rows with fromJson; older backups lack both keys.
    final WorkoutSet set = WorkoutSet.fromJson({
      'id': 500,
      'sessionId': 77,
      'exerciseId': null,
      'exerciseName': 'Leg Press',
      'setNumber': 1,
      'reps': 10,
      'weightKg': 120.0,
      'durationSeconds': null,
      'restSeconds': null,
      'rpe': null,
      'isWarmup': false,
      'isPr': true,
    });
    final WorkoutSession session = WorkoutSession.fromJson({
      'id': 77,
      'name': 'Push',
      'date': '2026-11-03',
      'notes': null,
      'createdAt': 1793728800000,
      'programSessionId': null,
    });
    expect(set.completedAt, isNull);
    expect(session.finishedAt, isNull);
  });
}
