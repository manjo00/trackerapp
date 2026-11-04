import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';

/// Opening a version-26 database (the schema before the habits rebuild) runs
/// the v27 upgrade: every habit keeps its row and gets the new defaults, a
/// "3 a week" habit becomes "N a week", duplicate ticks shrink to one, and the
/// new unique key refuses another duplicate. Other tables are untouched.
void main() {
  late AppDatabase db;

  // 25 Aug 2026 17:34 UTC and 1 Oct 2026 07:00 UTC, in seconds (drift's
  // default date format).
  const int hCreated = 1787679240;
  const int runCreated = 1790838000;

  setUp(() {
    final List<String> v26 = File('test/core/database/fixtures/schema_v26.sql')
        .readAsStringSync()
        .split(RegExp(r';\r?\n')) // a Windows checkout may add \r
        .where((String s) => s.trim().isNotEmpty)
        .toList();
    db = AppDatabase.forTesting(NativeDatabase.memory(setup: (raw) {
      for (final String statement in v26) {
        raw.execute(statement);
      }
      raw.execute('INSERT INTO habits (id, name, created_at, target_per_week, '
          "archived_at) VALUES (1, 'H', $hCreated, 7, $hCreated)");
      raw.execute('INSERT INTO habits (id, name, created_at, target_per_week) '
          "VALUES (2, 'Run', $runCreated, 3)");
      raw.execute('INSERT INTO habit_completions (id, habit_id, date) VALUES '
          "(10, 2, '2026-11-02'), (11, 2, '2026-11-02'), (12, 2, '2026-11-03')");
      raw.execute('INSERT INTO tasks (id, title, created_at) '
          "VALUES (5, 'Buy milk', $runCreated)");
      raw.execute('INSERT INTO workout_sessions (id, name, date, created_at) '
          "VALUES (77, 'Push', '2026-11-03', $runCreated)");
      raw.execute('PRAGMA user_version = 26');
    }));
  });

  tearDown(() => db.close());

  test('the upgrade lands on version 27', () async {
    final QueryRow row =
        await db.customSelect('PRAGMA user_version').getSingle();
    expect(row.read<int>('user_version'), 27);
  });

  test('habits keep their rows and get the defaults', () async {
    final Habit h = await (db.select(db.habits)
          ..where((t) => t.id.equals(1)))
        .getSingle();
    expect(h.name, 'H');
    expect(
      (h.kind, h.goal, h.step, h.schedule, h.weekdayMask, h.sparesPerWeek),
      ('tick', 1, 1, 'daily', 127, 0),
    );
    expect((h.section, h.icon, h.color, h.shiftMask, h.sortOrder),
        ('any', 'check_circle', 0, 7, 0));
    expect((h.unit, h.perWeek, h.cue, h.autoSource), (null, null, null, null));
    expect(
      h.archivedAt!.isAtSameMomentAs(
          DateTime.fromMillisecondsSinceEpoch(hCreated * 1000, isUtc: true)),
      isTrue,
    );
  });

  test('a target below 7 becomes N a week', () async {
    final Habit run = await (db.select(db.habits)
          ..where((t) => t.id.equals(2)))
        .getSingle();
    expect((run.schedule, run.perWeek), ('per_week', 3));
  });

  test('duplicate ticks shrink to one and the index refuses a new one',
      () async {
    final List<HabitCompletion> rows = await (db.select(db.habitCompletions)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    expect(rows.map((r) => r.id), [10, 12]);
    expect((rows.first.value, rows.first.status), (1, 'done'));
    await expectLater(
      db.customStatement('INSERT INTO habit_completions (habit_id, date) '
          "VALUES (2, '2026-11-03')"),
      throwsA(isA<SqliteException>()),
    );
  });

  test('habit_pauses exists and is empty', () async {
    expect(await db.select(db.habitPauses).get(), isEmpty);
  });

  test('other tables keep their rows', () async {
    final Task task = await db.select(db.tasks).getSingle();
    expect((task.id, task.title), (5, 'Buy milk'));
    final WorkoutSession session =
        await db.select(db.workoutSessions).getSingle();
    expect((session.id, session.name, session.date), (77, 'Push', '2026-11-03'));
  });
}
