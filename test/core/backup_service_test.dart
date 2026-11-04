import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/backup/backup_service.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/habits/data/dao/habits_dao.dart';
import 'package:life_tracker/features/habits/data/models/habit_model.dart';
import 'package:life_tracker/features/habits/data/repositories/habits_repository.dart';
import 'package:life_tracker/features/habits/domain/habit_types.dart';

/// Verifies the backup engine: a snapshot exported from one database can be
/// imported into a fresh database and restores the same rows.
void main() {
  test('export then import restores data (round-trip)', () async {
    final AppDatabase source = AppDatabase.forTesting(NativeDatabase.memory());

    // Seed a habit (+completion), a task, and a shift.
    final int habitId = await source.into(source.habits).insert(
          HabitsCompanion.insert(name: 'Run', createdAt: DateTime(2026, 1, 1)),
        );
    await source.into(source.habitCompletions).insert(
          HabitCompletionsCompanion.insert(
              habitId: habitId, date: '2026-01-01'),
        );
    await source.into(source.tasks).insert(
          TasksCompanion.insert(title: 'Buy milk', createdAt: DateTime(2026, 1, 2)),
        );
    await source.into(source.workShifts).insert(
          WorkShiftsCompanion.insert(
            date: '2026-07-03',
            shiftType: 'day',
            startTime: '07:00',
            endTime: '19:00',
          ),
        );

    final String json = await BackupService(source).exportToJson();
    await source.close();

    // Import into a brand-new database.
    final AppDatabase target = AppDatabase.forTesting(NativeDatabase.memory());
    await BackupService(target).importFromJson(json);

    final habits = await target.select(target.habits).get();
    final completions = await target.select(target.habitCompletions).get();
    final tasks = await target.select(target.tasks).get();
    final shifts = await target.select(target.workShifts).get();

    expect(habits.length, 1);
    expect(habits.first.name, 'Run');
    expect(completions.length, 1);
    expect(completions.first.date, '2026-01-01');
    expect(tasks.first.title, 'Buy milk');
    expect(shifts.first.shiftType, 'day');
    expect(shifts.first.startTime, '07:00');

    await target.close();
  });

  test('importing invalid JSON throws FormatException', () async {
    final AppDatabase db = AppDatabase.forTesting(NativeDatabase.memory());
    expect(
      () => BackupService(db).importFromJson('{"not":"a backup"}'),
      throwsA(isA<FormatException>()),
    );
    await db.close();
  });

  group('habits since schema 27', () {
    const List<String> newHabitKeys = [
      'kind', 'goal', 'unit', 'step', 'icon', 'color', 'schedule', //
      'weekdayMask', 'perWeek', 'shiftMask', 'sparesPerWeek', 'section',
      'cue', 'sortOrder', 'autoSource',
    ];
    const List<String> newTickKeys = ['value', 'status', 'note', 'createdAt'];

    /// A backup as an older version wrote it: no new habit or tick keys and
    /// no habit_pauses table. "Run" was a 3-days-a-week habit back then.
    Future<Map<String, dynamic>> oldBackup() async {
      final AppDatabase source = AppDatabase.forTesting(NativeDatabase.memory());
      final HabitsRepository repo = HabitsRepository(HabitsDao(source));
      final int read = await repo.saveHabit(HabitModel(
          id: 0, name: 'Read', createdAt: DateTime(2026, 10, 1, 10)));
      await repo.saveHabit(HabitModel(
          id: 0,
          name: 'Run',
          createdAt: DateTime(2026, 10, 1, 10),
          schedule: HabitSchedule.perWeek,
          perWeek: 3));
      await repo.toggleTick(read, '2026-11-02');
      final Map<String, dynamic> backup =
          jsonDecode(await BackupService(source).exportToJson())
              as Map<String, dynamic>;
      await source.close();
      final Map<String, dynamic> tables =
          backup['tables'] as Map<String, dynamic>;
      for (final dynamic row in tables['habits'] as List) {
        newHabitKeys.forEach((row as Map).remove);
      }
      for (final dynamic row in tables['habit_completions'] as List) {
        newTickKeys.forEach((row as Map).remove);
      }
      tables.remove('habit_pauses');
      return backup;
    }

    Future<AppDatabase> restored(Map<String, dynamic> backup) async {
      final AppDatabase target = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(target.close);
      await BackupService(target).importFromJson(jsonEncode(backup));
      return target;
    }

    test('an old backup without the new habit keys imports with defaults',
        () async {
      final AppDatabase db = await restored(await oldBackup());
      final Habit read = await (db.select(db.habits)
            ..where((h) => h.name.equals('Read')))
          .getSingle();
      expect(
          (read.kind, read.schedule, read.weekdayMask, read.sparesPerWeek,
              read.section),
          ('tick', 'daily', 127, 0, 'any'));
      final HabitCompletion tick = await db.select(db.habitCompletions).getSingle();
      expect((tick.date, tick.value, tick.status), ('2026-11-02', 1, 'done'));
    });

    test('an old 3-a-week habit imports as a few times a week', () async {
      final AppDatabase db = await restored(await oldBackup());
      final Habit run = await (db.select(db.habits)
            ..where((h) => h.name.equals('Run')))
          .getSingle();
      expect((run.schedule, run.perWeek), ('per_week', 3));
    });

    test('an old backup with a duplicate tick still imports, keeping one',
        () async {
      final Map<String, dynamic> backup = await oldBackup();
      final List<dynamic> ticks =
          (backup['tables'] as Map<String, dynamic>)['habit_completions']
              as List<dynamic>;
      ticks.add({...(ticks.first as Map), 'id': 999});
      final AppDatabase db = await restored(backup);
      expect(await db.select(db.habitCompletions).get(), hasLength(1));
    });

    test('habit pauses survive a backup and restore', () async {
      final AppDatabase source = AppDatabase.forTesting(NativeDatabase.memory());
      await source.into(source.habitPauses).insert(HabitPausesCompanion.insert(
          startDate: '2026-11-10',
          endDate: '2026-11-12',
          createdAt: DateTime(2026, 11, 4)));
      final String json = await BackupService(source).exportToJson();
      await source.close();
      final AppDatabase db = await restored(
          jsonDecode(json) as Map<String, dynamic>);
      expect(
          (await db.select(db.habitPauses).get())
              .map((p) => (p.startDate, p.endDate)),
          [('2026-11-10', '2026-11-12')]);
    });
  });
}
