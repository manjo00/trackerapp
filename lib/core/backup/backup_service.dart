import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';

/// Serialises the entire local database to JSON and restores it.
///
/// This is the engine behind Settings → Export / Import. It's deliberately
/// format-stable (one JSON object, one key per table) so a future Google Drive
/// sync can upload/download the exact same payload without changes.
///
/// Export uses [GeneratedDatabase.allTables] generically. Import is explicit
/// and ordered: rows are deleted children-first and re-inserted parents-first
/// so foreign-key constraints are always satisfied.
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  /// Bumped only if the JSON envelope shape changes (not the DB schema).
  static const int _formatVersion = 1;

  // ── Export ────────────────────────────────────────────────────────────────

  /// Returns a pretty-printed JSON snapshot of every table.
  Future<String> exportToJson() async {
    final Map<String, dynamic> tables = {};
    for (final TableInfo<Table, dynamic> table in _db.allTables) {
      final List<dynamic> rows = await _db.select(table).get();
      tables[table.actualTableName] =
          rows.map((r) => (r as dynamic).toJson()).toList();
    }

    return const JsonEncoder.withIndent('  ').convert({
      'formatVersion': _formatVersion,
      'schemaVersion': _db.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': tables,
    });
  }

  // ── Import ────────────────────────────────────────────────────────────────

  /// Replaces ALL current data with the contents of [jsonStr].
  ///
  /// Throws [FormatException] if the payload isn't a recognised backup.
  /// Runs inside a single transaction, so a failure rolls back cleanly and
  /// leaves the existing data intact.
  Future<void> importFromJson(String jsonStr) async {
    final dynamic decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic> || decoded['tables'] is! Map) {
      throw const FormatException('Not a valid Life Tracker backup file');
    }
    final Map<String, dynamic> tables =
        (decoded['tables'] as Map).cast<String, dynamic>();

    List<Map<String, dynamic>> rowsFor(String name) =>
        ((tables[name] as List?) ?? const [])
            .map((e) => (e as Map).cast<String, dynamic>())
            .toList();

    await _db.transaction(() async {
      // 1. Wipe everything, children before parents (FK-safe).
      for (final TableInfo<Table, dynamic> table in _deleteOrder) {
        await _db.delete(table).go();
      }

      // 2. Re-insert, parents before children.
      await _db.batch((b) {
        b.insertAll(_db.exerciseLibrary,
            rowsFor('exercise_library').map(ExerciseLibraryData.fromJson));
        b.insertAll(_db.programs, rowsFor('programs').map(Program.fromJson));
        b.insertAll(_db.programSessions,
            rowsFor('program_sessions').map(ProgramSession.fromJson));
        b.insertAll(_db.programExercises,
            rowsFor('program_exercises').map(ProgramExercise.fromJson));
        b.insertAll(_db.workoutSessions,
            rowsFor('workout_sessions').map(WorkoutSession.fromJson));
        b.insertAll(
            _db.workoutSets, rowsFor('workout_sets').map(WorkoutSet.fromJson));
        b.insertAll(_db.habits, rowsFor('habits').map(Habit.fromJson));
        b.insertAll(_db.habitCompletions,
            rowsFor('habit_completions').map(HabitCompletion.fromJson));
        b.insertAll(_db.customTrackers,
            rowsFor('custom_trackers').map(CustomTracker.fromJson));
        b.insertAll(_db.trackerItems,
            rowsFor('tracker_items').map(TrackerItem.fromJson));
        b.insertAll(
            _db.trackerLogs, rowsFor('tracker_logs').map(TrackerLog.fromJson));
        b.insertAll(_db.trackerLogValues,
            rowsFor('tracker_log_values').map(TrackerLogValue.fromJson));
        // Task organization (v11): lists + sections before tasks (FKs),
        // labels before the junction, junction after tasks.
        b.insertAll(
            _db.taskLists, rowsFor('task_lists').map(TaskList.fromJson));
        b.insertAll(_db.listSections,
            rowsFor('list_sections').map(ListSection.fromJson));
        b.insertAll(_db.labels, rowsFor('labels').map(Label.fromJson));
        b.insertAll(_db.tasks, rowsFor('tasks').map(Task.fromJson));
        b.insertAll(
            _db.taskLabels, rowsFor('task_labels').map(TaskLabel.fromJson));
        // Notes (v14): notebooks → notes → note_blocks (FK order). Photo image
        // FILES are not in this JSON — restored photo blocks show the
        // "Image unavailable" placeholder (cloud sync is the cross-device fix).
        b.insertAll(
            _db.notebooks, rowsFor('notebooks').map(Notebook.fromJson));
        b.insertAll(_db.notes, rowsFor('notes').map(Note.fromJson));
        b.insertAll(
            _db.noteBlocks, rowsFor('note_blocks').map(NoteBlock.fromJson));
        b.insertAll(
            _db.workShifts, rowsFor('work_shifts').map(WorkShift.fromJson));
        // Standalone tables that were missing from restore entirely
        // (exported fine, silently dropped on import until now).
        b.insertAll(_db.shiftRotations,
            rowsFor('shift_rotations').map(ShiftRotation.fromJson));
        b.insertAll(_db.muscleTargets,
            rowsFor('muscle_targets').map(MuscleTarget.fromJson));
      });
    });
  }

  /// Tables in delete order: children first, then their parents, so foreign
  /// keys are never violated while wiping.
  List<TableInfo<Table, dynamic>> get _deleteOrder => [
        _db.noteBlocks,
        _db.notes,
        _db.notebooks,
        _db.trackerLogValues,
        _db.trackerLogs,
        _db.trackerItems,
        _db.customTrackers,
        _db.workoutSets,
        _db.workoutSessions,
        _db.programExercises,
        _db.programSessions,
        _db.programs,
        _db.exerciseLibrary,
        _db.habitCompletions,
        _db.habits,
        _db.taskLabels,
        _db.labels,
        _db.tasks,
        _db.listSections,
        _db.taskLists,
        _db.workShifts,
        _db.shiftRotations,
        _db.muscleTargets,
      ];
}
