import 'package:drift/drift.dart';

import '../../../notes/data/tables/note_blocks_table.dart';
import 'task_lists_table.dart';

/// Defines the [tasks] table in SQLite.
///
/// Unlike habits (which track daily completions in a second table),
/// a task is a one-time item: it's either done or not.  The [isCompleted]
/// flag lives directly on this row — no companion table needed.
///
/// Priority is stored as an INTEGER (0 = low, 1 = medium, 2 = high) so
/// it can be sorted numerically.  The [TaskPriority] enum in
/// `task_priority.dart` maps between Dart and these integer values.
class Tasks extends Table {
  /// Unique row identifier — auto-assigned by SQLite on insert.
  IntColumn get id => integer().autoIncrement()();

  /// The task title, e.g. "Buy groceries".
  TextColumn get title => text().withLength(min: 1, max: 200)();

  /// Optional longer description or note for this task.
  TextColumn get note => text().nullable()();

  /// Optional due date stored as "yyyy-MM-dd" (e.g. "2026-05-27").
  /// NULL means no due date set.
  TextColumn get dueDate => text().nullable()();

  /// Priority level: 0 = low, 1 = medium, 2 = high.
  /// Default is medium (1) so new tasks are visible but not urgent.
  IntColumn get priority => integer().withDefault(const Constant(1))();

  /// Whether the task has been completed.
  /// Stored as 0 (false) or 1 (true) in SQLite.
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  /// When this task was created (UTC).
  DateTimeColumn get createdAt => dateTime()();

  /// Optional specific time of day the task is due, stored as "HH:mm".
  /// When null, "09:00" is used as the default for notification scheduling.
  TextColumn get dueTime => text().nullable()();

  /// Whether reminders are enabled for this task.
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(false))();

  /// Comma-separated lead-time intervals in minutes, e.g. "1440,180,5"
  /// means 1 day before, 3 hours before, and 5 minutes before the due time.
  /// NULL means no lead times selected.
  TextColumn get reminderLeadTimes => text().nullable()();

  /// Owning list; NULL = "Captured" (no Inbox row exists by design).
  IntColumn get listId => integer()
      .nullable()
      .references(TaskLists, #id, onDelete: KeyAction.setNull)();

  /// Section within [listId]'s list; NULL = list body. Repository guards
  /// that a section always belongs to the task's own list.
  IntColumn get sectionId => integer()
      .nullable()
      .references(ListSections, #id, onDelete: KeyAction.setNull)();

  /// Optional length of the task's time block in minutes ("time blocking").
  /// Only meaningful together with [dueTime] (the start); the end time is
  /// always computed so rescheduling the start moves the whole block.
  IntColumn get durationMinutes => integer().nullable()();

  /// When set, the task is archived — hidden from every active view but
  /// recoverable from the Archived screen. NULL = active.
  DateTimeColumn get archivedAt => dateTime().nullable()();

  /// Set when this task was auto-created from a note line (an "@time …" token).
  /// Points at the source [NoteBlocks] row; ON DELETE CASCADE means deleting
  /// that block — or the whole note it belongs to — deletes this task too.
  /// NULL = an ordinary, hand-made task.
  IntColumn get sourceNoteBlockId => integer()
      .nullable()
      .references(NoteBlocks, #id, onDelete: KeyAction.cascade)();
}
