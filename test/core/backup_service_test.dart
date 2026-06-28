import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/backup/backup_service.dart';
import 'package:life_tracker/core/database/app_database.dart';

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
}
