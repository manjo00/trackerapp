import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../features/habits/data/dao/habits_dao.dart';
import '../../features/habits/data/tables/habit_completions_table.dart';
import '../../features/habits/data/tables/habits_table.dart';
import '../../features/shifts/data/dao/shifts_dao.dart';
import '../../features/shifts/data/tables/work_shifts_table.dart';
import '../../features/tasks/data/dao/tasks_dao.dart';
import '../../features/tasks/data/tables/tasks_table.dart';
import '../../features/trackers/data/dao/trackers_dao.dart';
import '../../features/trackers/data/tables/custom_trackers_table.dart';
import '../../features/trackers/data/tables/tracker_items_table.dart';
import '../../features/trackers/data/tables/tracker_log_values_table.dart';
import '../../features/trackers/data/tables/tracker_logs_table.dart';
import '../../features/workout/data/dao/program_dao.dart';
import '../../features/workout/data/dao/workout_dao.dart';
import '../../features/workout/data/models/exercise_seed_data.dart';
import '../../features/workout/data/tables/exercise_library_table.dart';
import '../../features/workout/data/tables/program_exercises_table.dart';
import '../../features/workout/data/tables/program_sessions_table.dart';
import '../../features/workout/data/tables/programs_table.dart';
import '../../features/workout/data/tables/workout_sessions_table.dart';
import '../../features/workout/data/tables/workout_sets_table.dart';

part 'app_database.g.dart';

/// The single SQLite database for the whole app.
///
/// ## Adding a new feature checklist
/// 1. Create a table class in `features/{feature}/data/tables/`
/// 2. Create a DAO class in `features/{feature}/data/dao/`
/// 3. Add both to the lists in the [@DriftDatabase] annotation below
/// 4. Bump [schemaVersion] and add a migration step in [migration]
/// 5. Run `dart run build_runner build --delete-conflicting-outputs`
@DriftDatabase(
  tables: [
    // ── Habits ──────────────────────────────────────────────────────────────
    Habits,
    HabitCompletions,
    // ── Tasks ────────────────────────────────────────────────────────────────
    Tasks,
    // ── Trackers ─────────────────────────────────────────────────────────────
    CustomTrackers,
    TrackerItems,
    TrackerLogs,
    TrackerLogValues,
    // ── Workout ──────────────────────────────────────────────────────────────
    ExerciseLibrary,
    WorkoutSessions,
    WorkoutSets,
    // ── Programs (v5) ────────────────────────────────────────────────────────
    Programs,
    ProgramSessions,
    ProgramExercises,
    // ── Shifts (v6) ──────────────────────────────────────────────────────────
    WorkShifts,
  ],
  daos: [HabitsDao, TasksDao, TrackersDao, WorkoutDao, ProgramDao, ShiftsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Used in tests — runs against an in-memory DB, nothing written to disk.
  AppDatabase.forTesting(super.executor);

  /// Increment every time a table is added, removed, or changed.
  ///
  /// v1 → initial schema (habits, habit_completions)
  /// v2 → added tasks table
  /// v3 → added custom_trackers, tracker_items, tracker_logs, tracker_log_values
  /// v4 → added reminder columns to habits/tasks/custom_trackers,
  ///       isTemplate to custom_trackers,
  ///       workout tables (exercise_library, workout_sessions, workout_sets)
  /// v5 → added programs, program_sessions, program_exercises tables;
  ///       added programSessionId FK to workout_sessions
  /// v6 → added work_shifts table (hospital shift schedule)
  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedExerciseLibrary(m);
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(tasks);
          }
          if (from < 3) {
            await m.createTable(customTrackers);
            await m.createTable(trackerItems);
            await m.createTable(trackerLogs);
            await m.createTable(trackerLogValues);
          }
          if (from < 4) {
            await m.addColumn(habits, habits.reminderEnabled);
            await m.addColumn(habits, habits.reminderTime);
            await m.addColumn(tasks, tasks.dueTime);
            await m.addColumn(tasks, tasks.reminderEnabled);
            await m.addColumn(tasks, tasks.reminderLeadTimes);
            await m.addColumn(customTrackers, customTrackers.reminderEnabled);
            await m.addColumn(customTrackers, customTrackers.reminderTime);
            await m.addColumn(customTrackers, customTrackers.isTemplate);
            await m.createTable(exerciseLibrary);
            await m.createTable(workoutSessions);
            await m.createTable(workoutSets);
            await _seedExerciseLibrary(m);
          }
          if (from < 5) {
            // New program tables
            await m.createTable(programs);
            await m.createTable(programSessions);
            await m.createTable(programExercises);
            // New FK column on existing table
            await m.addColumn(
                workoutSessions, workoutSessions.programSessionId);
          }
          if (from < 6) {
            // Hospital shift schedule
            await m.createTable(workShifts);
          }
        },
        beforeOpen: (details) async {
          // SQLite ignores foreign keys unless this is set per-connection.
          // Without it, onDelete CASCADE / SET NULL never fire and deleting a
          // parent (habit, tracker, program) leaves orphaned child rows.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _seedExerciseLibrary(Migrator m) async {
    for (final exercise in kSeedExercises) {
      await into(exerciseLibrary).insert(
        ExerciseLibraryCompanion.insert(
          name: exercise['name']!,
          primaryMuscle: exercise['primaryMuscle']!,
          secondaryMuscles: Value(exercise['secondaryMuscles']),
          equipment: exercise['equipment']!,
        ),
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, 'life_tracker.db'));
    return NativeDatabase.createInBackground(file);
  });
}
