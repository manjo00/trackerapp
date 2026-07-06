import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../features/habits/data/dao/habits_dao.dart';
import '../../features/habits/data/tables/habit_completions_table.dart';
import '../../features/habits/data/tables/habits_table.dart';
import '../../features/shifts/data/dao/shifts_dao.dart';
import '../../features/shifts/data/tables/shift_rotations_table.dart';
import '../../features/shifts/data/tables/work_shifts_table.dart';
import '../../features/tasks/data/dao/tasks_dao.dart';
import '../../features/tasks/data/tables/labels_table.dart';
import '../../features/tasks/data/tables/task_lists_table.dart';
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
import '../../features/workout/data/tables/muscle_targets_table.dart';
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
    // ── Task organization (v11): lists, sections, labels ────────────────────
    TaskLists,
    ListSections,
    Labels,
    TaskLabels,
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
    // ── Shift rotations (v7) ─────────────────────────────────────────────────
    ShiftRotations,
    // ── Weekly muscle targets (v9) ───────────────────────────────────────────
    MuscleTargets,
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
  /// v7 → added shift_rotations table + rotationLabel/rotationColor on
  ///       work_shifts (editable rotation labels per day)
  /// v8 → recolour the default rotation label colour (washed-out orange →
  ///       a deeper, higher-contrast orange) on existing data
  /// v9 → added muscle_targets (weekly targets per muscle group); re-tagged the
  ///       "Arms" exercises into Biceps / Triceps / Forearms
  /// v10 → weekly targets are now per individual muscle (not per push/pull
  ///        group) so one muscle can't be masked by another; reseed targets
  /// v11 → task organization: task_lists, list_sections, labels, task_labels
  ///        tables + nullable listId/sectionId on tasks (NULL list = Captured)
  /// v12 → time blocking: nullable durationMinutes on tasks (with dueTime as
  ///        the start; end time is computed, never stored)
  @override
  int get schemaVersion => 12;

  /// The old vs. new default rotation-label colour (see v8 migration).
  static const int _oldRotationColor = 0xFFFFB347;
  static const int _newRotationColor = 0xFFF4511E;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedExerciseLibrary(m);
          await _seedRotations();
          await _seedMuscleTargets();
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
          if (from < 7) {
            // Editable rotation labels per shift.
            await m.createTable(shiftRotations);
            await m.addColumn(workShifts, workShifts.rotationLabel);
            await m.addColumn(workShifts, workShifts.rotationColor);
            await _seedRotations();
          }
          if (from < 8) {
            // Recolour the old default orange to the new higher-contrast one,
            // on both the rotation definitions and any assigned shifts.
            await (update(shiftRotations)
                  ..where((t) => t.colorValue.equals(_oldRotationColor)))
                .write(const ShiftRotationsCompanion(
                    colorValue: Value(_newRotationColor)));
            await (update(workShifts)
                  ..where((t) => t.rotationColor.equals(_oldRotationColor)))
                .write(const WorkShiftsCompanion(
                    rotationColor: Value(_newRotationColor)));
          }
          if (from < 9) {
            // Weekly muscle targets + split the broad "Arms" tag into
            // Biceps / Triceps / Forearms so push vs pull can be tracked.
            await m.createTable(muscleTargets);
            await _retagArmExercises();
          }
          if (from < 10) {
            // Targets are now per individual muscle, not per group. Reseed.
            await delete(muscleTargets).go();
            await _seedMuscleTargets();
          }
          if (from < 11) {
            // Task organization: lists, sections, labels. Existing tasks get
            // NULL listId ⇒ they all land in "Captured" — nothing to backfill.
            await m.createTable(taskLists);
            await m.createTable(listSections);
            await m.createTable(labels);
            await m.createTable(taskLabels);
            await m.addColumn(tasks, tasks.listId);
            await m.addColumn(tasks, tasks.sectionId);
          }
          if (from < 12) {
            // Time blocking: optional block length per task.
            await m.addColumn(tasks, tasks.durationMinutes);
          }
        },
        beforeOpen: (details) async {
          // SQLite ignores foreign keys unless this is set per-connection.
          // Without it, onDelete CASCADE / SET NULL never fire and deleting a
          // parent (habit, tracker, program) leaves orphaned child rows.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Seeds the default rotation labels (from the hospital rota). Editable later.
  /// Rotation labels are optional per-day tags on the shift calendar.
  /// Shipped empty — users add their own (any names/colours) in the
  /// rotations editor. (The original build seeded hospital-specific codes;
  /// removed so the shared app isn't tied to one person's job.)
  Future<void> _seedRotations() async {
    // Intentionally seeds nothing.
  }

  /// Seeds the per-muscle default weekly targets (frequency, sets/session).
  /// Editable later in the targets editor. groupKey holds the muscle tag.
  Future<void> _seedMuscleTargets() async {
    // (muscle, frequency, setsPerSession)
    const List<(String, int, int)> defaults = [
      ('Chest', 2, 3),
      ('Shoulders', 2, 3),
      ('Triceps', 2, 3),
      ('Back', 2, 3),
      ('Biceps', 2, 3),
      ('Forearms', 1, 3),
      ('Legs', 2, 3),
      ('Core', 2, 3),
    ];
    for (int i = 0; i < defaults.length; i++) {
      final (String key, int freq, int sets) = defaults[i];
      await into(muscleTargets).insert(
        MuscleTargetsCompanion.insert(
          groupKey: key,
          frequency: Value(freq),
          setsPerSession: Value(sets),
          orderIndex: Value(i),
        ),
      );
    }
  }

  /// Splits the broad "Arms" muscle tag on existing library rows into
  /// Biceps / Triceps / Forearms (so push and pull can be tracked separately).
  Future<void> _retagArmExercises() async {
    Future<void> retag(String name, String muscle) =>
        (update(exerciseLibrary)..where((t) => t.name.equals(name))).write(
          ExerciseLibraryCompanion(primaryMuscle: Value(muscle)),
        );
    await retag('Barbell Curl', 'Biceps');
    await retag('Dumbbell Curl', 'Biceps');
    await retag('Preacher Curl', 'Biceps');
    await retag('Hammer Curl', 'Forearms');
    await retag('Tricep Pushdown', 'Triceps');
    await retag('Skull Crusher', 'Triceps');
    await retag('Overhead Tricep Extension', 'Triceps');
  }

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
