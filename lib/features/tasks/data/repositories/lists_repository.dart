import 'package:drift/drift.dart' show Value;

import '../../../../core/database/app_database.dart';
import '../dao/lists_dao.dart';
import '../dao/tasks_dao.dart';

/// List/section/label operations for the presentation layer.
///
/// Mostly thin passthroughs to [ListsDao]; the one piece of real logic is
/// [moveTaskToList], which enforces the invariant that a task's section
/// always belongs to the task's own list.
class ListsRepository {
  ListsRepository(this._dao, this._tasksDao);

  final ListsDao _dao;
  final TasksDao _tasksDao;

  // ── Lists ─────────────────────────────────────────────────────────────────

  Stream<List<TaskList>> watchLists() => _dao.watchLists();

  Future<int> addList(String name, int colorValue) =>
      _dao.insertList(TaskListsCompanion.insert(
        name: name.trim(),
        colorValue: Value(colorValue),
        createdAt: DateTime.now(),
      ));

  Future<void> renameList(int id, String name, int colorValue) =>
      _dao.updateList(TaskListsCompanion(
        id: Value(id),
        name: Value(name.trim()),
        colorValue: Value(colorValue),
      ));

  Future<void> deleteList(int id) => _dao.deleteList(id);

  // ── Sections ──────────────────────────────────────────────────────────────

  Stream<List<ListSection>> watchSections(int listId) =>
      _dao.watchSections(listId);

  Future<int> addSection(int listId, String name) => _dao.insertSection(
      ListSectionsCompanion.insert(listId: listId, name: name.trim()));

  Future<void> renameSection(int id, String name) => _dao.updateSection(
      ListSectionsCompanion(id: Value(id), name: Value(name.trim())));

  Future<void> deleteSection(int id) => _dao.deleteSection(id);

  // ── Labels ────────────────────────────────────────────────────────────────

  Stream<List<Label>> watchLabels() => _dao.watchLabels();

  Future<int> addLabel(String name, int colorValue) =>
      _dao.insertLabel(LabelsCompanion.insert(
        name: name.trim(),
        colorValue: Value(colorValue),
      ));

  Future<void> deleteLabel(int id) => _dao.deleteLabel(id);

  Stream<List<int>> watchLabelIdsForTask(int taskId) =>
      _dao.watchLabelIdsForTask(taskId);

  Future<void> setTaskLabels(int taskId, Set<int> labelIds) =>
      _dao.setTaskLabels(taskId, labelIds);

  // ── Aggregates ────────────────────────────────────────────────────────────

  Stream<Map<int, int>> watchTaskCountsByList() => _dao.watchTaskCountsByList();

  // ── Moving tasks ──────────────────────────────────────────────────────────

  /// Files a task under [listId] (null = back to Captured).
  ///
  /// Guard: [sectionId] is kept only when that section actually belongs to
  /// the target list — otherwise it is nulled. This keeps the invariant
  /// "a task's section is inside its own list" true no matter what the
  /// caller passes (e.g. a stale section from the task's previous list).
  Future<void> moveTaskToList(int taskId, int? listId, {int? sectionId}) async {
    int? effectiveSection;
    if (sectionId != null && listId != null) {
      final ListSection? section = await _dao.getSection(sectionId);
      if (section != null && section.listId == listId) {
        effectiveSection = sectionId;
      }
    }
    await _tasksDao.updateTask(TasksCompanion(
      id: Value(taskId),
      listId: Value(listId),
      sectionId: Value(effectiveSection),
    ));
  }
}
