import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<int> addList(String name) => db.into(db.taskLists).insert(
      TaskListsCompanion.insert(name: name, createdAt: DateTime.now()));
  Future<int> addTask(String title, {int? listId, int? sectionId}) =>
      db.into(db.tasks).insert(TasksCompanion.insert(
          title: title,
          createdAt: DateTime.now(),
          listId: Value(listId),
          sectionId: Value(sectionId)));

  test('delete list -> tasks fall back to Captured, sections die', () async {
    final int l = await addList('Work');
    final int s = await db.into(db.listSections).insert(
        ListSectionsCompanion.insert(listId: l, name: 'Sprint'));
    final int t = await addTask('report', listId: l, sectionId: s);
    await (db.delete(db.taskLists)..where((r) => r.id.equals(l))).go();
    final task =
        await (db.select(db.tasks)..where((r) => r.id.equals(t))).getSingle();
    expect(task.listId, null);
    expect(task.sectionId, null);
    expect(await db.select(db.listSections).get(), isEmpty);
  });

  test('delete section -> task stays in list', () async {
    final int l = await addList('Home');
    final int s = await db.into(db.listSections).insert(
        ListSectionsCompanion.insert(listId: l, name: 'A'));
    final int t = await addTask('x', listId: l, sectionId: s);
    await (db.delete(db.listSections)..where((r) => r.id.equals(s))).go();
    final task =
        await (db.select(db.tasks)..where((r) => r.id.equals(t))).getSingle();
    expect(task.listId, l);
    expect(task.sectionId, null);
  });

  test('task_labels cascades from both sides', () async {
    final int t = await addTask('x');
    final int lb =
        await db.into(db.labels).insert(LabelsCompanion.insert(name: 'gym'));
    await db
        .into(db.taskLabels)
        .insert(TaskLabelsCompanion.insert(taskId: t, labelId: lb));
    await (db.delete(db.labels)..where((r) => r.id.equals(lb))).go();
    expect(await db.select(db.taskLabels).get(), isEmpty);
  });
}
