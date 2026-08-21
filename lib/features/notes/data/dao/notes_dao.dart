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

  Future<void> setNotebookDeleted(int id, DateTime? at) =>
      (update(notebooks)..where((n) => n.id.equals(id)))
          .write(NotebooksCompanion(deletedAt: Value(at)));

  /// Archived notebooks, most-recently-archived first (Archived screen).
  Stream<List<Notebook>> watchArchivedNotebooks() => (select(notebooks)
        ..where((n) => n.archivedAt.isNotNull() & n.deletedAt.isNull())
        ..orderBy([(n) => OrderingTerm.desc(n.archivedAt)]))
      .watch();

  /// Notebooks in Recently deleted, most-recently-deleted first.
  Stream<List<Notebook>> watchDeletedNotebooks() => (select(notebooks)
        ..where((n) => n.deletedAt.isNotNull())
        ..orderBy([(n) => OrderingTerm.desc(n.deletedAt)]))
      .watch();

  /// Really removes notebooks binned before [cutoff]. Their notes fall back to
  /// Unfiled (notebookId SET NULL) — but since the notes were binned alongside
  /// the notebook, they are normally purged in the same sweep.
  Future<int> purgeNotebooksDeletedBefore(DateTime cutoff) =>
      (delete(notebooks)..where((n) => n.deletedAt.isSmallerThanValue(cutoff)))
          .go();

  /// Archives every still-active note in a notebook with the notebook's own
  /// timestamp. The shared stamp is what lets [restoreNotesArchivedWith] bring
  /// back exactly the notes that went in together — no extra column needed.
  Future<int> archiveNotesInNotebook(int notebookId, DateTime at) =>
      (update(notes)
            ..where((n) => n.notebookId.equals(notebookId) & n.archivedAt.isNull()))
          .write(NotesCompanion(archivedAt: Value(at)));

  /// Un-archives the notes that were archived in the same action as their
  /// notebook (matched by identical timestamp). Notes the user had archived
  /// separately, earlier, stay archived.
  Future<int> restoreNotesArchivedWith(int notebookId, DateTime stamp) =>
      (update(notes)
            ..where((n) =>
                n.notebookId.equals(notebookId) & n.archivedAt.equals(stamp)))
          .write(const NotesCompanion(archivedAt: Value(null)));

  /// Bins/unbins every note in a notebook that isn't already in the state
  /// being set — used when a notebook is deleted or restored as a unit.
  Future<int> setNotesDeletedInNotebook(int notebookId, DateTime? at) =>
      (update(notes)
            ..where((n) => at == null
                ? n.notebookId.equals(notebookId) & n.deletedAt.isNotNull()
                : n.notebookId.equals(notebookId) & n.deletedAt.isNull()))
          .write(NotesCompanion(deletedAt: Value(at)));

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

  Future<void> setNoteDeleted(int id, DateTime? at) =>
      (update(notes)..where((n) => n.id.equals(id)))
          .write(NotesCompanion(deletedAt: Value(at)));

  /// One-shot fetch of a notebook (null if it doesn't exist). Restore uses it
  /// to check whether a note's notebook is itself archived.
  Future<Notebook?> getNotebook(int id) =>
      (select(notebooks)..where((n) => n.id.equals(id))).getSingleOrNull();

  /// Archived notes (templates included), most-recently-archived first.
  Stream<List<Note>> watchArchivedNotes() => (select(notes)
        ..where((n) => n.archivedAt.isNotNull() & n.deletedAt.isNull())
        ..orderBy([(n) => OrderingTerm.desc(n.archivedAt)]))
      .watch();

  /// Notes in Recently deleted, most-recently-deleted first.
  Stream<List<Note>> watchDeletedNotes() => (select(notes)
        ..where((n) => n.deletedAt.isNotNull())
        ..orderBy([(n) => OrderingTerm.desc(n.deletedAt)]))
      .watch();

  /// Really removes notes binned before [cutoff] (CASCADE takes their blocks).
  /// Photo FILES are deleted by NotesRepository before this runs — the DB row
  /// is the only thing that goes here.
  Future<int> purgeNotesDeletedBefore(DateTime cutoff) =>
      (delete(notes)..where((n) => n.deletedAt.isSmallerThanValue(cutoff)))
          .go();

  /// Notes whose time in the bin is up. The purge walks these one by one so
  /// each note's photo files can be deleted before its row is.
  Future<List<Note>> notesDeletedBefore(DateTime cutoff) =>
      (select(notes)..where((n) => n.deletedAt.isSmallerThanValue(cutoff)))
          .get();

  /// notebookId → the titles of the notes filed in it. Lets the Archived screen
  /// find a notebook by something inside it, not only by its name.
  Stream<Map<int, List<String>>> watchNoteTitlesByNotebook() {
    return (select(notes)..where((n) => n.notebookId.isNotNull()))
        .watch()
        .map((rows) {
      final Map<int, List<String>> byNotebook = {};
      for (final Note note in rows) {
        final int? id = note.notebookId;
        if (id == null) continue;
        byNotebook.putIfAbsent(id, () => <String>[]).add(note.title);
      }
      return byNotebook;
    });
  }

  /// The binned notes belonging to a notebook — what "delete the notebook
  /// forever" has to take with it.
  Future<List<Note>> deletedNotesInNotebook(int notebookId) => (select(notes)
        ..where((n) => n.notebookId.equals(notebookId) & n.deletedAt.isNotNull()))
      .get();

  /// The written content of every archived or binned note, joined per note —
  /// the "search inside an archived thing" body. Filtering happens in SQL so
  /// the whole block table never comes into memory. Photo blocks are skipped
  /// (their content is a filename, not prose).
  Stream<Map<int, String>> watchArchivedNoteText() {
    final query = select(noteBlocks).join(
      [innerJoin(notes, notes.id.equalsExp(noteBlocks.noteId))],
    )
      ..where(notes.archivedAt.isNotNull())
      ..orderBy([OrderingTerm.asc(noteBlocks.orderIndex)]);
    return query.watch().map((rows) {
      final Map<int, List<String>> byNote = {};
      for (final row in rows) {
        final NoteBlock b = row.readTable(noteBlocks);
        if (b.type == 'photo' || b.type == 'divider') continue;
        final String text = (b.content ?? '').trim();
        if (text.isEmpty) continue;
        byNote.putIfAbsent(b.noteId, () => <String>[]).add(text);
      }
      return byNote.map((k, v) => MapEntry(k, v.join('\n')));
    });
  }

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
