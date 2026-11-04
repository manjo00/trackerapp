import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/habits/data/dao/habits_dao.dart';
import 'package:life_tracker/features/habits/data/models/habit_model.dart';
import 'package:life_tracker/features/habits/data/models/habit_with_status.dart';
import 'package:life_tracker/features/habits/data/repositories/habits_repository.dart';
import 'package:life_tracker/features/habits/domain/habit_types.dart';

void main() {
  late AppDatabase db;
  late HabitsDao dao;
  late HabitsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = HabitsDao(db);
    repo = HabitsRepository(dao);
  });

  tearDown(() => db.close());

  HabitModel newHabit(String name, {int sortOrder = 0}) => HabitModel(
      id: 0,
      name: name,
      createdAt: DateTime(2026, 11, 1, 9),
      sortOrder: sortOrder);

  test('saveHabit stores every field and reads it back', () async {
    final HabitModel water = HabitModel(
      id: 0,
      name: 'Water',
      createdAt: DateTime(2026, 11, 1, 9),
      kind: HabitKind.count,
      goal: 8,
      unit: 'glasses',
      icon: 'water_drop',
      color: 5,
      schedule: HabitSchedule.weekdays,
      weekdayMask: 21,
      sparesPerWeek: 2,
      section: HabitSection.sleep,
      cue: 'After dinner',
      reminderEnabled: true,
      reminderTime: '21:00',
    );
    final int id = await repo.saveHabit(water);
    expect((await repo.watchActiveHabits().first).single,
        water.copyWith(id: id));

    await repo.saveHabit(water.copyWith(
        id: id, name: 'Water!', schedule: HabitSchedule.perWeek, perWeek: 3));
    final HabitModel updated = (await repo.watchActiveHabits().first).single;
    expect((updated.id, updated.name, updated.schedule, updated.perWeek),
        (id, 'Water!', HabitSchedule.perWeek, 3));
  });

  test('toggleTick once leaves one row (value 1, done); twice leaves none',
      () async {
    final int id = await repo.saveHabit(newHabit('Read'));
    await repo.toggleTick(id, '2026-11-04');
    final List<HabitCompletion> rows =
        await db.select(db.habitCompletions).get();
    expect(rows.map((r) => (r.habitId, r.date, r.value, r.status)),
        [(id, '2026-11-04', 1, 'done')]);
    await repo.toggleTick(id, '2026-11-04');
    expect(await db.select(db.habitCompletions).get(), isEmpty);
  });

  test('setValue upserts one row per day; 0 removes it', () async {
    final int id = await repo.saveHabit(newHabit('Water'));
    await repo.setValue(id, '2026-11-04', 3);
    await repo.setValue(id, '2026-11-04', 5);
    expect(
        (await db.select(db.habitCompletions).get())
            .map((r) => (r.date, r.value)),
        [('2026-11-04', 5)]);
    await repo.setValue(id, '2026-11-04', 0);
    expect(await db.select(db.habitCompletions).get(), isEmpty);
  });

  test("watchHabitsForDate marks only that day's ticks", () async {
    final int a = await repo.saveHabit(newHabit('A'));
    final int b = await repo.saveHabit(newHabit('B'));
    await repo.toggleTick(a, '2026-11-03');
    await repo.toggleTick(b, '2026-11-04');
    final List<HabitWithStatus> day =
        await repo.watchHabitsForDate('2026-11-03').first;
    expect(day.map((h) => (h.habit.name, h.isDoneToday)),
        [('A', true), ('B', false)]);
  });

  test(
      'watchActiveHabits leaves out archived and deleted habits, ordered by '
      'sortOrder then id', () async {
    await repo.saveHabit(newHabit('A', sortOrder: 2));
    await repo.saveHabit(newHabit('B', sortOrder: 1));
    await repo.saveHabit(newHabit('C', sortOrder: 1));
    final int d = await repo.saveHabit(newHabit('D'));
    final int e = await repo.saveHabit(newHabit('E'));
    await dao.setHabitArchived(d, DateTime(2026, 11, 2));
    await dao.setHabitArchived(e, DateTime(2026, 11, 2));
    await dao.setHabitDeleted(e, DateTime(2026, 11, 2));
    expect((await repo.watchActiveHabits().first).map((h) => h.name),
        ['B', 'C', 'A']);
  });

  test(
      'watchHistorySince groups entries per habit from that day on, with '
      'the pauses', () async {
    final int a = await repo.saveHabit(newHabit('A'));
    final int b = await repo.saveHabit(newHabit('B'));
    await repo.toggleTick(a, '2026-10-01');
    await repo.toggleTick(a, '2026-11-03');
    await repo.setValue(b, '2026-11-04', 5);
    await db.into(db.habitPauses).insert(HabitPausesCompanion.insert(
        startDate: '2026-11-10',
        endDate: '2026-11-12',
        createdAt: DateTime(2026, 11, 4)));
    final HabitHistories hist =
        await repo.watchHistorySince('2026-10-15').first;
    expect(hist.of(a).entries.keys, ['2026-11-03']);
    expect(hist.of(b).entries['2026-11-04']!.value, 5);
    expect(hist.of(a).pauses.single.start, '2026-11-10');
    expect(hist.of(999).entries, isEmpty);
  });
}
