import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/habits/data/dao/habits_dao.dart';
import 'package:life_tracker/features/tasks/data/dao/lists_dao.dart';
import 'package:life_tracker/features/tasks/data/dao/tasks_dao.dart';
import 'package:life_tracker/features/trackers/data/dao/trackers_dao.dart';

void main() {
  late AppDatabase db;
  late TasksDao tasksDao;
  late ListsDao listsDao;
  late HabitsDao habitsDao;
  late TrackersDao trackersDao;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tasksDao = TasksDao(db);
    listsDao = ListsDao(db);
    habitsDao = HabitsDao(db);
    trackersDao = TrackersDao(db);
  });
  tearDown(() async => db.close());

  final DateTime now = DateTime(2026, 7, 6, 12);

  Future<int> addTask(String title, {int? listId}) =>
      db.into(db.tasks).insert(TasksCompanion.insert(
          title: title, createdAt: now, listId: Value(listId)));

  test('archiving a task hides it from the active watch, shows in archived',
      () async {
    final TasksDao dao = tasksDao;
    final int t = await addTask('groceries');

    expect((await dao.watchAllTasks().first).map((r) => r.id), [t]);
    expect(await dao.watchArchivedTasks().first, isEmpty);

    await dao.setTaskArchived(t, now);
    expect(await dao.watchAllTasks().first, isEmpty);
    expect((await dao.watchArchivedTasks().first).map((r) => r.id), [t]);

    await dao.setTaskArchived(t, null); // unarchive
    expect((await dao.watchAllTasks().first).map((r) => r.id), [t]);
    expect(await dao.watchArchivedTasks().first, isEmpty);
  });

  test('delete-forever removes an archived task entirely', () async {
    final TasksDao dao = tasksDao;
    final int t = await addTask('x');
    await dao.setTaskArchived(t, now);
    await dao.deleteTask(t);
    expect(await dao.watchArchivedTasks().first, isEmpty);
    expect(await dao.watchAllTasks().first, isEmpty);
  });

  test('archiving a list keeps its tasks; list leaves the active watch',
      () async {
    final ListsDao lists = listsDao;
    final int l = await lists.insertList(
        TaskListsCompanion.insert(name: 'Work', createdAt: now));
    final int t = await addTask('report', listId: l);

    await lists.setListArchived(l, now);

    // List gone from active, present in archived.
    expect(await lists.watchLists().first, isEmpty);
    expect((await lists.watchArchivedLists().first).map((r) => r.id), [l]);
    // Its task survives (still active, still points at the list id).
    final row = await (db.select(db.tasks)..where((r) => r.id.equals(t)))
        .getSingle();
    expect(row.archivedAt, null);
    expect(row.listId, l);
  });

  test('archived habits and trackers leave their active watches', () async {
    final int h = await db.into(db.habits).insert(
        HabitsCompanion.insert(name: 'run', createdAt: now));
    await habitsDao.setHabitArchived(h, now);
    expect(await habitsDao.watchAllHabits().first, isEmpty);
    expect((await habitsDao.watchArchivedHabits().first).map((r) => r.id),
        [h]);

    final int tr = await db.into(db.customTrackers).insert(
        CustomTrackersCompanion.insert(
            name: 'meds',
            templateType: 'daily_checklist',
            icon: '💊',
            colorValue: 0xFF000000,
            createdAt: now));
    await trackersDao.setTrackerArchived(tr, now);
    expect(await trackersDao.watchAllTrackers().first, isEmpty);
    expect(
        (await trackersDao.watchArchivedTrackers().first).map((r) => r.id),
        [tr]);
  });
}
