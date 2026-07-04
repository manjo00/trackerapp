import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/features/tasks/data/dao/lists_dao.dart';
import 'package:life_tracker/features/tasks/data/dao/tasks_dao.dart';
import 'package:life_tracker/features/tasks/data/repositories/lists_repository.dart';

void main() {
  late AppDatabase db;
  late ListsDao listsDao;
  late TasksDao tasksDao;
  late ListsRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    listsDao = ListsDao(db);
    tasksDao = TasksDao(db);
    repo = ListsRepository(listsDao, tasksDao);
  });
  tearDown(() async => db.close());

  Future<int> addList(String name) => listsDao.insertList(
      TaskListsCompanion.insert(name: name, createdAt: DateTime.now()));
  Future<int> addSection(int listId, String name) => listsDao
      .insertSection(ListSectionsCompanion.insert(listId: listId, name: name));
  Future<int> addTask(String title,
          {int? listId,
          int? sectionId,
          String? dueDate,
          bool isCompleted = false}) =>
      tasksDao.insertTask(TasksCompanion.insert(
          title: title,
          createdAt: DateTime.now(),
          listId: Value(listId),
          sectionId: Value(sectionId),
          dueDate: Value(dueDate),
          isCompleted: Value(isCompleted)));

  test('create list + section + assign task', () async {
    final int l = await addList('Work');
    final int s = await addSection(l, 'Sprint');
    final int t = await addTask('report', listId: l, sectionId: s);

    final lists = await listsDao.watchLists().first;
    expect(lists.map((r) => r.name), ['Work']);
    final sections = await listsDao.watchSections(l).first;
    expect(sections.map((r) => r.name), ['Sprint']);
    final tasks = await tasksDao.watchTasksForList(l).first;
    expect(tasks.map((r) => r.id), [t]);
  });

  test('moveTaskToList to another list clears stale section', () async {
    final int l1 = await addList('A');
    final int s1 = await addSection(l1, 'A1');
    final int l2 = await addList('B');
    final int t = await addTask('x', listId: l1, sectionId: s1);

    // Move to l2 while (incorrectly) passing l1's section — guard nulls it.
    await repo.moveTaskToList(t, l2, sectionId: s1);

    final row = await (db.select(db.tasks)..where((r) => r.id.equals(t)))
        .getSingle();
    expect(row.listId, l2);
    expect(row.sectionId, null);
  });

  test('setTaskLabels replaces the set atomically', () async {
    final int t = await addTask('x');
    final int gym =
        await listsDao.insertLabel(LabelsCompanion.insert(name: 'gym'));
    final int home =
        await listsDao.insertLabel(LabelsCompanion.insert(name: 'home'));
    final int urgent =
        await listsDao.insertLabel(LabelsCompanion.insert(name: 'urgent'));

    await listsDao.setTaskLabels(t, {gym, home});
    expect((await listsDao.watchLabelIdsForTask(t).first).toSet(), {gym, home});

    await listsDao.setTaskLabels(t, {urgent});
    expect(await listsDao.watchLabelIdsForTask(t).first, [urgent]);
  });

  test('watchCapturedTasks: unassigned only, dated or not', () async {
    final int l = await addList('Work');
    await addTask('in a list', listId: l);
    final int dated = await addTask('dated captured', dueDate: '2026-07-10');
    final int undated = await addTask('undated captured');
    await addTask('done captured', isCompleted: true);

    final captured = await tasksDao.watchCapturedTasks().first;
    expect(captured.map((r) => r.id).toSet(), {dated, undated});
  });

  test('watchTaskCountsByList counts only incomplete', () async {
    final int l = await addList('Work');
    await addTask('open 1', listId: l);
    await addTask('open 2', listId: l);
    await addTask('done', listId: l, isCompleted: true);
    await addTask('captured'); // no list — must not appear

    final counts = await listsDao.watchTaskCountsByList().first;
    expect(counts, {l: 2});
  });
}
