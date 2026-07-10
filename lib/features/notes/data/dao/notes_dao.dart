import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../models/note_block_type.dart';
import '../tables/note_blocks_table.dart';
import '../tables/notebooks_table.dart';
import '../tables/notes_table.dart';

part 'notes_dao.g.dart';

/// Queries for notebooks, notes, and the blocks that make up a note.
///
/// Active watches exclude archived rows (`archivedAt IS NULL`). Constructed
/// directly (`NotesDao(db)`) like [ListsDao] — not registered in the generated
/// `daos:` list.
@DriftAccessor(tables: [Notebooks, Notes, NoteBlocks])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(super.db);

  // ── Notebooks ───────────────────────────────────────────────────────────

  /// Active notebooks, in user order (then name for stable ties).
  Stream<List<Notebook>> watchNotebooks() => (select(notebooks)
        ..where((n) => n.archivedAt.isNull())
        ..orderBy([
          (n) => OrderingTerm.asc(n.orderIndex),
          (n) => OrderingTerm.asc(n.name),
        ]))
      .watch();

  Future<int> createNotebook({
    required String name,
    required int colorValue,
    required String icon,
    required DateTime now,
  }) async {
    final int maxOrder = await _maxNotebookOrder();
    return into(notebooks).insert(NotebooksCompanion.insert(
      name: name,
      colorValue: Value(colorValue),
      icon: Value(icon),
      orderIndex: Value(maxOrder + 1),
      createdAt: now,
    ));
  }

  Future<int> _maxNotebookOrder() async {
    final max = notebooks.orderIndex.max();
    final row = await (selectOnly(notebooks)..addColumns([max])).getSingle();
    return row.read(max) ?? -1;
  }

  Future<void> renameNotebook(
          int id, String name, int colorValue, String icon) =>
      (update(notebooks)..where((n) => n.id.equals(id))).write(
          NotebooksCompanion(
              name: Value(name),
              colorValue: Value(colorValue),
              icon: Value(icon)));

  Future<void> setNotebookArchived(int id, DateTime? at) =>
      (update(notebooks)..where((n) => n.id.equals(id)))
          .write(NotebooksCompanion(archivedAt: Value(at)));

  /// Deletes a notebook; its notes fall back to Unfiled (notebookId SET NULL).
  Future<void> deleteNotebook(int id) =>
      (delete(notebooks)..where((n) => n.id.equals(id))).go();

  // ── Notes ───────────────────────────────────────────────────────────────

  /// Active notes in a notebook (or Unfiled when [notebookId] is null),
  /// most-recently-edited first.
  Stream<List<Note>> watchNotes(int? notebookId) {
    final query = select(notes)..where((n) => n.archivedAt.isNull());
    if (notebookId == null) {
      query.where((n) => n.notebookId.isNull());
    } else {
      query.where((n) => n.notebookId.equals(notebookId));
    }
    query.orderBy([(n) => OrderingTerm.desc(n.updatedAt)]);
    return query.watch();
  }

  /// One-shot fetch of a single note (used to seed the editor's title field).
  Future<Note?> getNote(int id) =>
      (select(notes)..where((n) => n.id.equals(id))).getSingleOrNull();

  Future<int> createNote({int? notebookId, required DateTime now}) =>
      into(notes).insert(NotesCompanion.insert(
        notebookId: Value(notebookId),
        createdAt: now,
        updatedAt: now,
      ));

  Future<void> updateNoteTitle(int id, String title, DateTime now) =>
      (update(notes)..where((n) => n.id.equals(id)))
          .write(NotesCompanion(title: Value(title), updatedAt: Value(now)));

  Future<void> touchNote(int id, DateTime now) =>
      (update(notes)..where((n) => n.id.equals(id)))
          .write(NotesCompanion(updatedAt: Value(now)));

  Future<void> setNoteArchived(int id, DateTime? at) =>
      (update(notes)..where((n) => n.id.equals(id)))
          .write(NotesCompanion(archivedAt: Value(at)));

  /// One-shot fetch of a note's blocks (pre-delete photo-file cleanup).
  Future<List<NoteBlock>> getBlocks(int noteId) =>
      (select(noteBlocks)..where((b) => b.noteId.equals(noteId))).get();

  Future<void> deleteNote(int id) =>
      (delete(notes)..where((n) => n.id.equals(id))).go();

  // ── Blocks ──────────────────────────────────────────────────────────────

  Stream<List<NoteBlock>> watchBlocks(int noteId) => (select(noteBlocks)
        ..where((b) => b.noteId.equals(noteId))
        ..orderBy([
          (b) => OrderingTerm.asc(b.orderIndex),
          (b) => OrderingTerm.asc(b.id),
        ]))
      .watch();

  Future<int> addBlock({
    required int noteId,
    required NoteBlockType type,
    String? content,
    required int orderIndex,
  }) =>
      into(noteBlocks).insert(NoteBlocksCompanion.insert(
        noteId: noteId,
        type: type.storageKey,
        content: Value(content),
        orderIndex: Value(orderIndex),
      ));

  Future<void> updateBlockContent(int id, String content) =>
      (update(noteBlocks)..where((b) => b.id.equals(id)))
          .write(NoteBlocksCompanion(content: Value(content)));

  Future<void> setBlockChecked(int id, bool checked) =>
      (update(noteBlocks)..where((b) => b.id.equals(id)))
          .write(NoteBlocksCompanion(checked: Value(checked)));

  Future<void> deleteBlock(int id) =>
      (delete(noteBlocks)..where((b) => b.id.equals(id))).go();
}
