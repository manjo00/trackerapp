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
        b.insertAll(_db.habits, rowsFor('habits').map(_habitFromJson));
        b.insertAll(_db.habitCompletions,
            _onePerHabitDay(rowsFor('habit_completions')));
        b.insertAll(_db.habitPauses,
            rowsFor('habit_pauses').map(HabitPause.fromJson));
        b.insertAll(_db.customTrackers,
            rowsFor('custom_trackers').map(CustomTracker.fromJson));
        b.insertAll(_db.trackerItems,
            rowsFor('tracker_items').map(TrackerItem.fromJson));
        b.insertAll(
            _db.trackerLogs, rowsFor('tracker_logs').map(TrackerLog.fromJson));
        b.insertAll(_db.trackerLogValues,
            rowsFor('tracker_log_values').map(TrackerLogValue.fromJson));
        // Notes (v14) MUST be inserted before task_lists/tasks: since v15,
        // task_lists.sourceNoteId → notes and tasks.sourceNoteBlockId →
        // note_blocks, so those parent rows have to exist first. Photo image
        // FILES aren't in this JSON — restored photo blocks show the
        // "Image unavailable" placeholder (cloud sync is the cross-device fix).
        b.insertAll(
            _db.notebooks, rowsFor('notebooks').map(Notebook.fromJson));
        b.insertAll(_db.notes, rowsFor('notes').map(Note.fromJson));
        b.insertAll(
            _db.noteBlocks, rowsFor('note_blocks').map(NoteBlock.fromJson));
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
        b.insertAll(
            _db.workShifts, rowsFor('work_shifts').map(WorkShift.fromJson));
        // Standalone tables that were missing from restore entirely
        // (exported fine, silently dropped on import until now).
        b.insertAll(_db.shiftRotations,
            rowsFor('shift_rotations').map(ShiftRotation.fromJson));
        b.insertAll(_db.muscleTargets,
            rowsFor('muscle_targets').map(MuscleTarget.fromJson));
        // Home dashboard layout (v21) — FK-free, order doesn't matter.
        b.insertAll(
            _db.homeBlocks, rowsFor('home_blocks').map(HomeBlock.fromJson));
      });
    });
  }

  // ── Habits from before schema 27 ─────────────────────────────────────────

  /// The habit columns schema 27 added, with the values a habit made before
  /// it gets (a daily tick, no spare days, "Any time").
  static const Map<String, dynamic> _habitDefaults = {
    'kind': 'tick',
    'goal': 1,
    'unit': null,
    'step': 1,
    'icon': 'check_circle',
    'color': 0,
    'schedule': 'daily',
    'weekdayMask': 127,
    'perWeek': null,
    'shiftMask': 7,
    'sparesPerWeek': 0,
    'section': 'any',
    'cue': null,
    'sortOrder': 0,
    'autoSource': null,
  };

  static const Map<String, dynamic> _tickDefaults = {
    'value': 1,
    'status': 'done',
    'note': null,
    'createdAt': null,
  };

  /// A habit row from any version: missing keys get the defaults, and an old
  /// "days a week" target below 7 becomes "N a week" (as the v27 upgrade does).
  static Habit _habitFromJson(Map<String, dynamic> row) {
    final Map<String, dynamic> filled = {..._habitDefaults, ...row};
    final int target = (row['targetPerWeek'] as num?)?.toInt() ?? 7;
    if (!row.containsKey('schedule') && target < 7) {
      filled['schedule'] = 'per_week';
      filled['perWeek'] = target;
    }
    return Habit.fromJson(filled);
  }

  /// Ticks from any version, at most one per habit and day (the first one):
  /// older versions could save a day twice, which the unique key now refuses.
  static List<HabitCompletion> _onePerHabitDay(
      List<Map<String, dynamic>> rows) {
    final Set<String> seen = {};
    return [
      for (final Map<String, dynamic> row in rows)
        if (seen.add('${row['habitId']}|${row['date']}'))
          HabitCompletion.fromJson({..._tickDefaults, ...row}),
    ];
  }

  /// Tables in delete order: children first, then their parents, so foreign
  /// keys are never violated while wiping.
  List<TableInfo<Table, dynamic>> get _deleteOrder => [
        // v15 FKs: tasks → note_blocks and task_lists → notes, so the whole
        // task cluster must be wiped before the notes cluster.
        _db.taskLabels,
        _db.tasks,
        _db.listSections,
        _db.taskLists,
        _db.labels,
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
        _db.habitPauses,
        _db.habits,
        _db.workShifts,
        _db.shiftRotations,
        _db.muscleTargets,
        _db.homeBlocks,
      ];
}
