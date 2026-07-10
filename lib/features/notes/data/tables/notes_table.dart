import 'package:drift/drift.dart';

import 'notebooks_table.dart';

/// A single note. Its body lives in [NoteBlocks], not here — this row only
/// holds the title and metadata.
///
/// notebookId NULL = "Unfiled" (no row exists for Unfiled, mirroring the
/// Captured-list convention). Deleting a notebook SET NULLs its notes, so they
/// fall back to Unfiled rather than vanishing.
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get notebookId => integer()
      .nullable()
      .references(Notebooks, #id, onDelete: KeyAction.setNull)();
  TextColumn get title => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  /// Bumped on every edit — sorts recently-edited first, and is the
  /// last-write-wins key a future cloud sync will need.
  DateTimeColumn get updatedAt => dateTime()();

  /// NULL = active; non-null = archived.
  DateTimeColumn get archivedAt => dateTime().nullable()();
}
