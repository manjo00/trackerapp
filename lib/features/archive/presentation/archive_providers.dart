import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../habits/data/dao/habits_dao.dart';
import '../../notes/presentation/providers/notes_providers.dart';
import '../../tasks/data/dao/tasks_dao.dart';
import '../../tasks/presentation/providers/lists_providers.dart';
import '../../trackers/data/dao/trackers_dao.dart';
import '../domain/archive_service.dart';
import '../domain/archived_item.dart';

export '../domain/archive_service.dart' show ArchiveService, kTrashRetention;

final archiveServiceProvider = Provider<ArchiveService>((ref) => ArchiveService(
      ref.watch(appDatabaseProvider),
      ref.watch(notesRepositoryProvider),
    ));

// ── DAOs ──────────────────────────────────────────────────────────────────────

final _tasksDaoForArchiveProvider =
    Provider<TasksDao>((ref) => TasksDao(ref.watch(appDatabaseProvider)));
final _trackersDaoForArchiveProvider = Provider<TrackersDao>(
    (ref) => TrackersDao(ref.watch(appDatabaseProvider)));
final _habitsDaoForArchiveProvider =
    Provider<HabitsDao>((ref) => HabitsDao(ref.watch(appDatabaseProvider)));

// ── Archived items (the Archived tab) ─────────────────────────────────────────

final archivedTasksProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(_tasksDaoForArchiveProvider).watchArchivedTasks());
final archivedListsProvider = StreamProvider<List<TaskList>>(
    (ref) => ref.watch(listsDaoProvider).watchArchivedLists());
final archivedHabitsProvider = StreamProvider<List<Habit>>(
    (ref) => ref.watch(_habitsDaoForArchiveProvider).watchArchivedHabits());
final archivedTrackersProvider = StreamProvider<List<CustomTracker>>((ref) =>
    ref.watch(_trackersDaoForArchiveProvider).watchArchivedTrackers());
final archivedNotesProvider = StreamProvider<List<Note>>(
    (ref) => ref.watch(notesDaoProvider).watchArchivedNotes());
final archivedNotebooksProvider = StreamProvider<List<Notebook>>(
    (ref) => ref.watch(notesDaoProvider).watchArchivedNotebooks());

// ── Deleted items (the Recently deleted tab) ──────────────────────────────────

final deletedTasksProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(_tasksDaoForArchiveProvider).watchDeletedTasks());
final deletedListsProvider = StreamProvider<List<TaskList>>(
    (ref) => ref.watch(listsDaoProvider).watchDeletedLists());
final deletedHabitsProvider = StreamProvider<List<Habit>>(
    (ref) => ref.watch(_habitsDaoForArchiveProvider).watchDeletedHabits());
final deletedTrackersProvider = StreamProvider<List<CustomTracker>>((ref) =>
    ref.watch(_trackersDaoForArchiveProvider).watchDeletedTrackers());
final deletedNotesProvider = StreamProvider<List<Note>>(
    (ref) => ref.watch(notesDaoProvider).watchDeletedNotes());
final deletedNotebooksProvider = StreamProvider<List<Notebook>>(
    (ref) => ref.watch(notesDaoProvider).watchDeletedNotebooks());

/// noteId → the written content of that note, for every archived or deleted
/// note. Feeds "search inside an archived thing".
final archivedNoteTextProvider = StreamProvider<Map<int, String>>(
    (ref) => ref.watch(notesDaoProvider).watchArchivedNoteText());

/// listId → the titles of the tasks inside it (a list's searchable contents).
final taskTitlesByListProvider = StreamProvider<Map<int, List<String>>>((ref) =>
    ref.watch(_tasksDaoForArchiveProvider).watchTaskTitlesByList());

/// notebookId → the titles of its notes (a notebook's searchable contents).
final noteTitlesByNotebookProvider = StreamProvider<Map<int, List<String>>>(
    (ref) => ref.watch(notesDaoProvider).watchNoteTitlesByNotebook());

// ── Flattened, searchable views ───────────────────────────────────────────────

/// Everything in the Archived tab as one list of [ArchivedItem]s — the shape
/// searchArchive() can filter. Each item carries its *contents* as well as its
/// name, which is what lets the search look inside.
final archivedItemsProvider = Provider<List<ArchivedItem>>((ref) => _flatten(
      tasks: ref.watch(archivedTasksProvider).valueOrNull ?? const [],
      lists: ref.watch(archivedListsProvider).valueOrNull ?? const [],
      habits: ref.watch(archivedHabitsProvider).valueOrNull ?? const [],
      trackers: ref.watch(archivedTrackersProvider).valueOrNull ?? const [],
      notes: ref.watch(archivedNotesProvider).valueOrNull ?? const [],
      notebooks: ref.watch(archivedNotebooksProvider).valueOrNull ?? const [],
      noteText: ref.watch(archivedNoteTextProvider).valueOrNull ?? const {},
      taskTitles: ref.watch(taskTitlesByListProvider).valueOrNull ?? const {},
      noteTitles:
          ref.watch(noteTitlesByNotebookProvider).valueOrNull ?? const {},
    ));

/// The same flattening for the Recently deleted tab.
final deletedItemsProvider = Provider<List<ArchivedItem>>((ref) => _flatten(
      tasks: ref.watch(deletedTasksProvider).valueOrNull ?? const [],
      lists: ref.watch(deletedListsProvider).valueOrNull ?? const [],
      habits: ref.watch(deletedHabitsProvider).valueOrNull ?? const [],
      trackers: ref.watch(deletedTrackersProvider).valueOrNull ?? const [],
      notes: ref.watch(deletedNotesProvider).valueOrNull ?? const [],
      notebooks: ref.watch(deletedNotebooksProvider).valueOrNull ?? const [],
      noteText: ref.watch(archivedNoteTextProvider).valueOrNull ?? const {},
      taskTitles: ref.watch(taskTitlesByListProvider).valueOrNull ?? const {},
      noteTitles:
          ref.watch(noteTitlesByNotebookProvider).valueOrNull ?? const {},
    ));

List<ArchivedItem> _flatten({
  required List<Task> tasks,
  required List<TaskList> lists,
  required List<Habit> habits,
  required List<CustomTracker> trackers,
  required List<Note> notes,
  required List<Notebook> notebooks,
  required Map<int, String> noteText,
  required Map<int, List<String>> taskTitles,
  required Map<int, List<String>> noteTitles,
}) {
  return <ArchivedItem>[
    for (final Task t in tasks)
      ArchivedItem(
        kind: ArchivedKind.task,
        id: t.id,
        title: t.title,
        body: t.note ?? '',
        archivedAt: t.archivedAt,
        deletedAt: t.deletedAt,
      ),
    for (final TaskList l in lists)
      ArchivedItem(
        kind: ArchivedKind.list,
        id: l.id,
        title: l.name,
        body: (taskTitles[l.id] ?? const <String>[]).join('\n'),
        colorValue: l.colorValue,
        archivedAt: l.archivedAt,
        deletedAt: l.deletedAt,
      ),
    for (final Habit h in habits)
      ArchivedItem(
        kind: ArchivedKind.habit,
        id: h.id,
        title: h.name,
        archivedAt: h.archivedAt,
        deletedAt: h.deletedAt,
      ),
    for (final CustomTracker tr in trackers)
      ArchivedItem(
        kind: ArchivedKind.tracker,
        id: tr.id,
        title: tr.name,
        body: tr.description ?? '',
        colorValue: tr.colorValue,
        archivedAt: tr.archivedAt,
        deletedAt: tr.deletedAt,
      ),
    for (final Note n in notes)
      ArchivedItem(
        kind: ArchivedKind.note,
        id: n.id,
        title: n.title.trim().isEmpty ? 'Untitled note' : n.title,
        body: noteText[n.id] ?? '',
        archivedAt: n.archivedAt,
        deletedAt: n.deletedAt,
      ),
    for (final Notebook nb in notebooks)
      ArchivedItem(
        kind: ArchivedKind.notebook,
        id: nb.id,
        title: nb.name,
        body: (noteTitles[nb.id] ?? const <String>[]).join('\n'),
        colorValue: nb.colorValue,
        archivedAt: nb.archivedAt,
        deletedAt: nb.deletedAt,
      ),
  ];
}
