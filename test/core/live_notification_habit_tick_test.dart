import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/core/notifications/live_background_callback.dart';
import 'package:life_tracker/features/habits/data/dao/habits_dao.dart';
import 'package:life_tracker/features/habits/data/models/habit_model.dart';
import 'package:life_tracker/features/habits/data/repositories/habits_repository.dart';

/// The live notification's ✓ for a habit saves the habit day, like the app:
/// the day starts at 04:00, so a tick at 01:30 counts for the night before.
void main() {
  late AppDatabase db;
  late HabitsDao dao;
  late int id;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = HabitsDao(db);
    id = await HabitsRepository(dao).saveHabit(
        HabitModel(id: 0, name: 'Read', createdAt: DateTime(2026, 10, 1, 10)));
  });

  tearDown(() => db.close());

  test('a tick at 01:30 counts for the day before', () async {
    await completeHabitFromNotification(dao, id, DateTime(2026, 11, 5, 1, 30));
    final List<HabitCompletion> rows = await db.select(db.habitCompletions).get();
    expect(rows.map((r) => r.date), ['2026-11-04']);
  });

  test('a second ✓ the same day changes nothing', () async {
    await completeHabitFromNotification(dao, id, DateTime(2026, 11, 4, 18));
    await completeHabitFromNotification(dao, id, DateTime(2026, 11, 5, 2));
    expect(await db.select(db.habitCompletions).get(), hasLength(1));
  });
}
