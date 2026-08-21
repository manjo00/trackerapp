import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/database/app_database.dart';
import 'package:life_tracker/core/images/image_storage_service.dart';
import 'package:life_tracker/features/archive/domain/archive_service.dart';
import 'package:life_tracker/features/habits/data/dao/habits_dao.dart';
import 'package:life_tracker/features/notes/data/dao/notes_dao.dart';
import 'package:life_tracker/features/notes/data/repositories/notes_repository.dart';
import 'package:life_tracker/features/tasks/data/dao/lists_dao.dart';
import 'package:life_tracker/features/tasks/data/dao/tasks_dao.dart';

/// The three-state machine: active → archived → recently deleted → gone.
/// What matters here isn't that a flag flips, but that restoring puts things
/// back **where they came from** and that a deleted row is invisible to the
/// ordinary app without every active query having to know about it.
void main() {
  late AppDatabase db;
  late ArchiveService archive;
  late HabitsDao habits;
  late TasksDao tasks;
  late ListsDao lists;
  late NotesDao notes;

  final DateTime now = DateTime(2026, 8, 21, 12);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    habits = HabitsDao(db);
    tasks = TasksDao(db);
    lists = ListsDao(db);
    notes = NotesDao(db);
    archive = ArchiveService(db, NotesRepository(notes, ImageStorageService()));
  });
  tearDown(() async => db.close());

  Future<int> addHabit(String name) => db
      .into(db.habits)
      .insert(HabitsCompanion.insert(name: name, createdAt: now));

  Future<int> addTask(String title, {int? listId}) =>
      db.into(db.tasks).insert(TasksCompanion.insert(
          title: title, createdAt: now, listId: Value(listId)));

  List<int> ids(List<dynamic> rows) => [for (final r in rows) r.id as int];

  group('deleting from live', () {
    test('goes to the bin, out of both the app and the Archived tab', () async {
      final int h = await addHabit('Gym');
      await archive.trashHabit(h, now);

      expect(await habits.watchAllHabits().first, isEmpty);
      expect(await habits.watchArchivedHabits().first, isEmpty);
      expect(ids(await habits.watchDeletedHabits().first), [h]);
    });

    test('restoring puts it back in the app, not in the archive', () async {
      final int h = await addHabit('Gym');
      await archive.trashHabit(h, now);
      await archive.restoreHabitFromTrash(h);

      expect(ids(await habits.watchAllHabits().first), [h]);
      expect(await habits.watchArchivedHabits().first, isEmpty);
      expect(await habits.watchDeletedHabits().first, isEmpty);
    });
  });

  group('deleting from the archive', () {
    test('restoring puts it back in the archive, not into the app', () async {
      final int h = await addHabit('Gym');
      await archive.archiveHabit(h, now);
      await archive.trashHabit(h, now.add(const Duration(days: 2)));

      expect(ids(await habits.watchDeletedHabits().first), [h]);

      await archive.restoreHabitFromTrash(h);
      expect(ids(await habits.watchArchivedHabits().first), [h]);
      expect(await habits.watchAllHabits().first, isEmpty);
    });
  });

  group('restore makes things visible again', () {
    test('restoring a task also brings back its archived list', () async {
      final int l = await lists.insertList(
          TaskListsCompanion.insert(name: 'Work', createdAt: now));
      final int t = await addTask('Send the report', listId: l);

      await archive.archiveTask(t, now);
      await archive.archiveList(l, now);
      await archive.restoreTask(t);

      // Without this rule the task would come back into a list that isn't
      // there — visible nowhere.
      expect(ids(await lists.watchLists().first), [l]);
      expect(ids(await tasks.watchAllTasks().first), [t]);
    });

    test('restoring a note also brings back its archived notebook', () async {
      final int nb = await notes.createNotebook(
          name: 'Recipes', colorValue: 1, icon: '📓', now: now);
      final int n = await notes.createNote(notebookId: nb, now: now);

      await archive.archiveNotebook(nb, now);
      await archive.restoreNote(n);

      expect(ids(await notes.watchNotebooks().first), [nb]);
      expect(ids(await notes.watchNotes(nb).first), [n]);
    });
  });

  group('a notebook and its notes travel together', () {
    test('archiving takes the notes with it', () async {
      final int nb = await notes.createNotebook(
          name: 'Recipes', colorValue: 1, icon: '📓', now: now);
      final int a = await notes.createNote(notebookId: nb, now: now);
      final int b = await notes.createNote(notebookId: nb, now: now);

      await archive.archiveNotebook(nb, now);

      expect(await notes.watchNotes(nb).first, isEmpty);
      expect(ids(await notes.watchArchivedNotes().first)..sort(), [a, b]);
    });

    test('restoring brings back exactly the notes that went in with it',
        () async {
      final int nb = await notes.createNotebook(
          name: 'Recipes', colorValue: 1, icon: '📓', now: now);
      final int together = await notes.createNote(notebookId: nb, now: now);
      final int onItsOwn = await notes.createNote(notebookId: nb, now: now);

      // The user archived this one deliberately, days earlier.
      await archive.archiveNote(
          onItsOwn, now.subtract(const Duration(days: 3)));
      await archive.archiveNotebook(nb, now);
      await archive.restoreNotebook(nb);

      // Only the note that was swept up comes back; the deliberate one stays.
      expect(ids(await notes.watchNotes(nb).first), [together]);
      expect(ids(await notes.watchArchivedNotes().first), [onItsOwn]);
    });

    test('deleting a notebook bins its notes too', () async {
      final int nb = await notes.createNotebook(
          name: 'Recipes', colorValue: 1, icon: '📓', now: now);
      final int n = await notes.createNote(notebookId: nb, now: now);

      await archive.trashNotebook(nb, now);

      expect(ids(await notes.watchDeletedNotebooks().first), [nb]);
      expect(ids(await notes.watchDeletedNotes().first), [n]);
    });
  });

  group('purging', () {
    test('removes only what is past 30 days', () async {
      final int old = await addHabit('Old');
      final int recent = await addHabit('Recent');
      await archive.trashHabit(old, now.subtract(const Duration(days: 31)));
      await archive.trashHabit(recent, now.subtract(const Duration(days: 5)));

      final int removed = await archive.purgeExpired(now);

      expect(removed, 1);
      expect(ids(await habits.watchDeletedHabits().first), [recent]);
    });

    test('emptying the bin takes everything in it, and nothing else', () async {
      final int binned = await addHabit('Binned');
      final int archived = await addHabit('Archived');
      final int live = await addHabit('Live');
      await archive.trashHabit(binned, now);
      await archive.archiveHabit(archived, now);

      await archive.emptyTrash(now);

      expect(await habits.watchDeletedHabits().first, isEmpty);
      expect(ids(await habits.watchArchivedHabits().first), [archived]);
      expect(ids(await habits.watchAllHabits().first), [live]);
    });
  });
}
