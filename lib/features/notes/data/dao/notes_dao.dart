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
    final query = select(notes)
      ..where((n) => n.archivedAt.isNull() & n.isTemplate.equals(false));
    if (notebookId == null) {
      query.where((n) => n.notebookId.isNull());
    } else {
      query.where((n) => n.notebookId.equals(notebookId));
    }
    query.orderBy([(n) => OrderingTerm.desc(n.updatedAt)]);
    return query.watch();
  }

  /// Active templates (isTemplate = true), most-recently-edited first.
  Stream<List<Note>> watchTemplates() => (select(notes)
        ..where((n) => n.archivedAt.isNull() & n.isTemplate.equals(true))
        ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]))
      .watch();

  /// One-shot fetch of a single note (used to seed the editor's title field).
  Future<Note?> getNote(int id) =>
      (select(notes)..where((n) => n.id.equals(id))).getSingleOrNull();

  /// Live view of one note — null once it's deleted. Drives the Home
  /// pinned-note block's title + "note gone" placeholder.
  Stream<Note?> watchNote(int id) =>
      (select(notes)..where((n) => n.id.equals(id))).watchSingleOrNull();

  /// Every active, non-template note across all notebooks (newest-edited
  /// first) — the pinned-note picker.
  Stream<List<Note>> watchAllNotes() => (select(notes)
        ..where((n) => n.archivedAt.isNull() & n.isTemplate.equals(false))
        ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]))
      .watch();

  Future<int> createNote(
          {int? notebookId,
          bool isTemplate = false,
          required DateTime now}) =>
      into(notes).insert(NotesCompanion.insert(
        notebookId: Value(notebookId),
        createdAt: now,
        updatedAt: now,
        isTemplate: Value(isTemplate),
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

  /// One-shot fetch of a note's blocks, in order.
  Future<List<NoteBlock>> getBlocks(int noteId) => (select(noteBlocks)
        ..where((b) => b.noteId.equals(noteId))
        ..orderBy([
          (b) => OrderingTerm.asc(b.orderIndex),
          (b) => OrderingTerm.asc(b.id),
        ]))
      .get();

  /// Latest note-edit time per notebook (notebookId → max updatedAt), for the
  /// Home "recent notebooks" block. Notebooks with no active notes are absent.
  Stream<Map<int, DateTime>> watchLastNoteEditByNotebook() {
    final maxUpdated = notes.updatedAt.max();
    final query = selectOnly(notes)
      ..addColumns([notes.notebookId, maxUpdated])
      ..where(notes.archivedAt.isNull() &
          notes.notebookId.isNotNull() &
          notes.isTemplate.equals(false))
      ..groupBy([notes.notebookId]);
    return query.watch().map((rows) {
      final Map<int, DateTime> out = {};
      for (final row in rows) {
        final int? nb = row.read(notes.notebookId);
        final DateTime? u = row.read(maxUpdated);
        if (nb != null && u != null) out[nb] = u;
      }
      return out;
    });
  }

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

  /// One-shot fetch of a single block by id (null if gone).
  Future<NoteBlock?> getBlock(int id) =>
      (select(noteBlocks)..where((b) => b.id.equals(id))).getSingleOrNull();

  Future<int> addBlock({
    required int noteId,
    required NoteBlockType type,
    String? content,
    required int orderIndex,
    int indent = 0,
  }) =>
      into(noteBlocks).insert(NoteBlocksCompanion.insert(
        noteId: noteId,
        type: type.storageKey,
        content: Value(content),
        orderIndex: Value(orderIndex),
        indent: Value(indent),
      ));

  /// Inserts a new block immediately after [afterOrderIndex] within a note,
  /// shifting every later block down by one so order stays contiguous. Used by
  /// the editor's Enter-to-new-line flow. Returns the new block's id.
  Future<int> insertBlockAfter({
    required int noteId,
    required NoteBlockType type,
    String? content,
    required int afterOrderIndex,
    int indent = 0,
  }) =>
      transaction(() async {
        final List<NoteBlock> later = await (select(noteBlocks)
              ..where((b) =>
                  b.noteId.equals(noteId) &
                  b.orderIndex.isBiggerThanValue(afterOrderIndex)))
            .get();
        for (final NoteBlock b in later) {
          await (update(noteBlocks)..where((r) => r.id.equals(b.id)))
              .write(NoteBlocksCompanion(orderIndex: Value(b.orderIndex + 1)));
        }
        return into(noteBlocks).insert(NoteBlocksCompanion.insert(
          noteId: noteId,
          type: type.storageKey,
          content: Value(content),
          orderIndex: Value(afterOrderIndex + 1),
          indent: Value(indent),
        ));
      });

  /// Inserts [companions] (each already carrying every field) starting at
  /// [atOrderIndex], shifting existing blocks at/after that index down by the
  /// batch size — one transaction. Used to instantiate / insert a template.
  /// The noteId and orderIndex of each companion are overwritten here.
  Future<void> insertBlocksAt(
    int noteId,
    int atOrderIndex,
    List<NoteBlocksCompanion> companions,
  ) =>
      transaction(() async {
        final int n = companions.length;
        if (n == 0) return;
        final List<NoteBlock> after = await (select(noteBlocks)
              ..where((b) =>
                  b.noteId.equals(noteId) &
                  b.orderIndex.isBiggerOrEqualValue(atOrderIndex)))
            .get();
        for (final NoteBlock b in after) {
          await (update(noteBlocks)..where((r) => r.id.equals(b.id)))
              .write(NoteBlocksCompanion(orderIndex: Value(b.orderIndex + n)));
        }
        for (int i = 0; i < n; i++) {
          await into(noteBlocks).insert(companions[i].copyWith(
            noteId: Value(noteId),
            orderIndex: Value(atOrderIndex + i),
          ));
        }
      });

  Future<void> updateBlockContent(int id, String content) =>
      (update(noteBlocks)..where((b) => b.id.equals(id)))
          .write(NoteBlocksCompanion(content: Value(content)));

  /// Updates a block's whole-line formatting flags. Only non-null args change;
  /// omitted ones are left as-is (`Value.absent()`). `content` is never touched.
  Future<void> setBlockFormat(
    int id, {
    int? headingLevel,
    bool? highlighted,
    bool? bold,
    bool? italic,
  }) =>
      (update(noteBlocks)..where((b) => b.id.equals(id))).write(
        NoteBlocksCompanion(
          headingLevel:
              headingLevel == null ? const Value.absent() : Value(headingLevel),
          highlighted:
              highlighted == null ? const Value.absent() : Value(highlighted),
          bold: bold == null ? const Value.absent() : Value(bold),
          italic: italic == null ? const Value.absent() : Value(italic),
        ),
      );

  Future<void> setBlockChecked(int id, bool checked) =>
      (update(noteBlocks)..where((b) => b.id.equals(id)))
          .write(NoteBlocksCompanion(checked: Value(checked)));

  /// A7: fold/unfold a single heading's section (persisted per block).
  Future<void> setBlockCollapsed(int id, bool collapsed) =>
      (update(noteBlocks)..where((b) => b.id.equals(id)))
          .write(NoteBlocksCompanion(collapsed: Value(collapsed)));

  /// A7 Collapse-all / Expand-all: flips every heading block in the note
  /// (headingLevel != 0), leaving body / checkbox / photo / divider untouched.
  Future<void> setAllHeadingsCollapsed(int noteId, bool collapsed) =>
      (update(noteBlocks)
            ..where((b) =>
                b.noteId.equals(noteId) & b.headingLevel.isBiggerThanValue(0)))
          .write(NoteBlocksCompanion(collapsed: Value(collapsed)));

  Future<void> deleteBlock(int id) =>
      (delete(noteBlocks)..where((b) => b.id.equals(id))).go();

  /// Rewrites block order for a note: [orderedIds] in their new top-to-bottom
  /// order become orderIndex 0,1,2,… in a single transaction.
  Future<void> reorderBlocks(List<int> orderedIds) => transaction(() async {
        for (int i = 0; i < orderedIds.length; i++) {
          await (update(noteBlocks)..where((b) => b.id.equals(orderedIds[i])))
              .write(NoteBlocksCompanion(orderIndex: Value(i)));
        }
      });

  /// Commits an arrange-mode drop: new order AND new outline depth in one
  /// transaction, so a block never renders at the wrong indent mid-write.
  Future<void> applyArrangement(
    List<int> orderedIds,
    Map<int, int> indentById,
  ) =>
      transaction(() async {
        for (int i = 0; i < orderedIds.length; i++) {
          final int id = orderedIds[i];
          await (update(noteBlocks)..where((b) => b.id.equals(id))).write(
            NoteBlocksCompanion(
              orderIndex: Value(i),
              indent: Value(indentById[id] ?? 0),
            ),
          );
        }
      });

  /// Keeps the outline sane when a line's heading level changes: a line that
  /// BECOMES a heading adopts the plain lines that follow it at its own depth
  /// (they become its children); a heading that becomes a plain line releases
  /// its children back up one level.
  Future<void> reflowAfterHeadingChange(int noteId, int blockId) =>
      transaction(() async {
        final List<NoteBlock> list = await getBlocks(noteId);
        final int i = list.indexWhere((b) => b.id == blockId);
        if (i < 0) return;
        final NoteBlock me = list[i];
        final int d = me.indent;
        final bool nowHeading =
            me.type == NoteBlockType.text.storageKey && me.headingLevel != 0;

        Future<void> setIndent(NoteBlock b, int v) =>
            (update(noteBlocks)..where((r) => r.id.equals(b.id)))
                .write(NoteBlocksCompanion(indent: Value(v)));

        for (int j = i + 1; j < list.length; j++) {
          final NoteBlock b = list[j];
          final bool isHeading =
              b.type == NoteBlockType.text.storageKey && b.headingLevel != 0;
          if (nowHeading) {
            if (b.indent < d) break;
            if (b.indent == d && isHeading) break; // the next bed starts here
            await setIndent(b, b.indent + 1);
          } else {
            if (b.indent <= d) break;
            await setIndent(b, b.indent - 1);
          }
        }
      });
}
