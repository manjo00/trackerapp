import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../tables/labels_table.dart';
import '../tables/task_lists_table.dart';
import '../tables/tasks_table.dart';

part 'lists_dao.g.dart';

/// Queries for task lists, their sections, and labels.
///
/// Tasks themselves stay in [TasksDao]; this DAO owns the organization
/// structures around them (containers, sections, tags).
@DriftAccessor(tables: [TaskLists, ListSections, Labels, TaskLabels, Tasks])
class ListsDao extends DatabaseAccessor<AppDatabase> with _$ListsDaoMixin {
  ListsDao(super.db);

  // ── Lists ─────────────────────────────────────────────────────────────────

  /// All lists, in user order (then name for stable ties).
  Stream<List<TaskList>> watchLists() {
    return (select(taskLists)
          ..orderBy([
            (l) => OrderingTerm.asc(l.orderIndex),
            (l) => OrderingTerm.asc(l.name),
          ]))
        .watch();
  }

  Future<int> insertList(TaskListsCompanion companion) =>
      into(taskLists).insert(companion);

  Future<void> updateList(TaskListsCompanion companion) =>
      (update(taskLists)..where((l) => l.id.equals(companion.id.value)))
          .write(companion);

  /// Deletes a list. Sections die via CASCADE; the list's tasks fall back
  /// to Captured via SET NULL — no app code needed for either.
  Future<int> deleteList(int listId) =>
      (delete(taskLists)..where((l) => l.id.equals(listId))).go();

  // ── Sections ──────────────────────────────────────────────────────────────

  Stream<List<ListSection>> watchSections(int listId) {
    return (select(listSections)
          ..where((s) => s.listId.equals(listId))
          ..orderBy([
            (s) => OrderingTerm.asc(s.orderIndex),
            (s) => OrderingTerm.asc(s.id),
          ]))
        .watch();
  }

  /// One-shot lookup used by the repository's move-to-list guard.
  Future<ListSection?> getSection(int sectionId) =>
      (select(listSections)..where((s) => s.id.equals(sectionId)))
          .getSingleOrNull();

  Future<int> insertSection(ListSectionsCompanion companion) =>
      into(listSections).insert(companion);

  Future<void> updateSection(ListSectionsCompanion companion) =>
      (update(listSections)..where((s) => s.id.equals(companion.id.value)))
          .write(companion);

  /// Deletes a section; its tasks stay in the list (sectionId SET NULL).
  Future<int> deleteSection(int sectionId) =>
      (delete(listSections)..where((s) => s.id.equals(sectionId))).go();

  // ── Labels ────────────────────────────────────────────────────────────────

  Stream<List<Label>> watchLabels() {
    return (select(labels)
          ..orderBy([
            (l) => OrderingTerm.asc(l.orderIndex),
            (l) => OrderingTerm.asc(l.name),
          ]))
        .watch();
  }

  Future<int> insertLabel(LabelsCompanion companion) =>
      into(labels).insert(companion);

  /// Deletes a label; junction rows die via CASCADE (tag vanishes off tasks).
  Future<int> deleteLabel(int labelId) =>
      (delete(labels)..where((l) => l.id.equals(labelId))).go();

  /// The label ids attached to one task (for the editor's chip row).
  Stream<List<int>> watchLabelIdsForTask(int taskId) {
    return (select(taskLabels)..where((tl) => tl.taskId.equals(taskId)))
        .watch()
        .map((rows) => rows.map((r) => r.labelId).toList());
  }

  /// Replaces a task's label set atomically (delete-then-insert so the
  /// caller never observes a half-updated set).
  Future<void> setTaskLabels(int taskId, Set<int> labelIds) {
    return transaction(() async {
      await (delete(taskLabels)..where((tl) => tl.taskId.equals(taskId))).go();
      for (final int labelId in labelIds) {
        await into(taskLabels).insert(
            TaskLabelsCompanion.insert(taskId: taskId, labelId: labelId));
      }
    });
  }

  // ── Aggregates ────────────────────────────────────────────────────────────

  /// Incomplete-task count per list id (lists with zero tasks are absent —
  /// the UI treats a missing key as 0).
  Stream<Map<int, int>> watchTaskCountsByList() {
    final countExp = tasks.id.count();
    final query = selectOnly(tasks)
      ..addColumns([tasks.listId, countExp])
      ..where(tasks.isCompleted.equals(false) & tasks.listId.isNotNull())
      ..groupBy([tasks.listId]);
    return query.watch().map((rows) {
      final Map<int, int> counts = {};
      for (final row in rows) {
        final int? listId = row.read(tasks.listId);
        if (listId != null) counts[listId] = row.read(countExp) ?? 0;
      }
      return counts;
    });
  }
}
