import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../habits/data/dao/habits_dao.dart';
import '../../tasks/data/dao/lists_dao.dart';
import '../../tasks/data/dao/tasks_dao.dart';
import '../../tasks/presentation/providers/lists_providers.dart';
import '../../trackers/data/dao/trackers_dao.dart';

/// One place to archive / restore / delete-forever any archivable item.
/// Talks straight to the DAOs (which own the archivedAt column) so the four
/// features don't each need parallel repo plumbing.
class ArchiveService {
  ArchiveService(AppDatabase db)
      : _tasks = TasksDao(db),
        _lists = ListsDao(db),
        _habits = HabitsDao(db),
        _trackers = TrackersDao(db);

  final TasksDao _tasks;
  final ListsDao _lists;
  final HabitsDao _habits;
  final TrackersDao _trackers;

  // Archive (stamp) / restore (clear). `now` is passed in so the caller
  // controls the timestamp (tests inject a fixed value).
  Future<void> archiveTask(int id, DateTime now) =>
      _tasks.setTaskArchived(id, now);
  Future<void> restoreTask(int id) => _tasks.setTaskArchived(id, null);
  Future<void> deleteTask(int id) => _tasks.deleteTask(id);

  Future<void> archiveList(int id, DateTime now) =>
      _lists.setListArchived(id, now);
  Future<void> restoreList(int id) => _lists.setListArchived(id, null);
  Future<void> deleteList(int id) => _lists.deleteList(id);

  Future<void> archiveHabit(int id, DateTime now) =>
      _habits.setHabitArchived(id, now);
  Future<void> restoreHabit(int id) => _habits.setHabitArchived(id, null);
  Future<void> deleteHabit(int id) => _habits.deleteHabit(id);

  Future<void> archiveTracker(int id, DateTime now) =>
      _trackers.setTrackerArchived(id, now);
  Future<void> restoreTracker(int id) => _trackers.setTrackerArchived(id, null);
  Future<void> deleteTracker(int id) => _trackers.deleteTracker(id);
}

final archiveServiceProvider = Provider<ArchiveService>(
    (ref) => ArchiveService(ref.watch(appDatabaseProvider)));

// ── Archived-item streams (feed the Archived screen) ───────────────────────

final _tasksDaoForArchiveProvider =
    Provider<TasksDao>((ref) => TasksDao(ref.watch(appDatabaseProvider)));
final _trackersDaoForArchiveProvider = Provider<TrackersDao>(
    (ref) => TrackersDao(ref.watch(appDatabaseProvider)));
final _habitsDaoForArchiveProvider =
    Provider<HabitsDao>((ref) => HabitsDao(ref.watch(appDatabaseProvider)));

final archivedTasksProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(_tasksDaoForArchiveProvider).watchArchivedTasks());
final archivedListsProvider = StreamProvider<List<TaskList>>(
    (ref) => ref.watch(listsDaoProvider).watchArchivedLists());
final archivedHabitsProvider = StreamProvider<List<Habit>>(
    (ref) => ref.watch(_habitsDaoForArchiveProvider).watchArchivedHabits());
final archivedTrackersProvider = StreamProvider<List<CustomTracker>>((ref) =>
    ref.watch(_trackersDaoForArchiveProvider).watchArchivedTrackers());
