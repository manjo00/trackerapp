import 'package:drift/drift.dart' show Value;
import 'package:image_picker/image_picker.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/images/image_storage_service.dart';
import '../dao/notes_dao.dart';
import '../models/note_block_type.dart';

/// Coordinates [NotesDao] and [ImageStorageService] so screens never have to
/// orchestrate a file write + a DB write together.
///
/// Plain text/checkbox mutations go straight through the [dao]; only the
/// photo-aware operations (which touch the filesystem) live here.
class NotesRepository {
  NotesRepository(this._dao, this._images);

  final NotesDao _dao;
  final ImageStorageService _images;

  NotesDao get dao => _dao;

  /// Picks a photo and, if one was chosen, appends a photo block + bumps the
  /// note's updatedAt. No-op when the user cancels the picker.
  Future<void> addPhotoBlock(
    int noteId,
    ImageSource source,
    int orderIndex, {
    required DateTime now,
  }) async {
    final String? filename = await _images.pickAndStore(source);
    if (filename == null) return; // cancelled
    await _dao.addBlock(
      noteId: noteId,
      type: NoteBlockType.photo,
      content: filename,
      orderIndex: orderIndex,
    );
    await _dao.touchNote(noteId, now);
  }

  /// Opens the crop editor on a photo block. On success the block points at the
  /// freshly cropped file and the old file is deleted. No-op if cancelled.
  Future<void> cropPhotoBlock(NoteBlock block, {required DateTime now}) async {
    final String? old = block.content;
    if (old == null || old.isEmpty) return;
    final String? newName = await _images.cropExisting(old);
    if (newName == null) return; // cancelled or missing file
    await _dao.updateBlockContent(block.id, newName);
    await _images.delete(old);
    await _dao.touchNote(block.noteId, now);
  }

  /// Removes a photo block and deletes its backing file.
  Future<void> removePhotoBlock(NoteBlock block, {required DateTime now}) async {
    final String? filename = block.content;
    if (filename != null && filename.isNotEmpty) {
      await _images.delete(filename);
    }
    await _dao.deleteBlock(block.id);
    await _dao.touchNote(block.noteId, now);
  }

  // ── Templates ─────────────────────────────────────────────────────────────

  /// Builds companions for every block of [fromNoteId] in order, duplicating
  /// photo files so a copy never shares an image with its source. noteId /
  /// orderIndex are placeholders — [NotesDao.insertBlocksAt] overwrites them.
  Future<List<NoteBlocksCompanion>> _copyCompanions(int fromNoteId) async {
    final List<NoteBlock> src = await _dao.getBlocks(fromNoteId)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final List<NoteBlocksCompanion> out = [];
    for (final NoteBlock b in src) {
      String? content = b.content;
      if (b.type == NoteBlockType.photo.storageKey &&
          content != null &&
          content.isNotEmpty) {
        content = await _images.duplicate(content);
      }
      out.add(NoteBlocksCompanion.insert(
        noteId: 0,
        type: b.type,
        content: Value(content),
        checked: Value(b.checked),
        orderIndex: const Value(0),
        headingLevel: Value(b.headingLevel),
        highlighted: Value(b.highlighted),
        bold: Value(b.bold),
        italic: Value(b.italic),
      ));
    }
    return out;
  }

  /// Saves an existing note as a new template (title + all blocks, photos
  /// duplicated). Returns the new template's id.
  Future<int> saveAsTemplate(int noteId, {required DateTime now}) async {
    final Note? src = await _dao.getNote(noteId);
    final int tmpl = await _dao.createNote(now: now, isTemplate: true);
    if (src != null && src.title.isNotEmpty) {
      await _dao.updateNoteTitle(tmpl, src.title, now);
    }
    await _dao.insertBlocksAt(tmpl, 0, await _copyCompanions(noteId));
    return tmpl;
  }

  /// Creates a new ordinary note in [notebookId] from a template (title +
  /// blocks, photos duplicated). Returns the new note's id.
  Future<int> newNoteFromTemplate(int templateId,
      {int? notebookId, required DateTime now}) async {
    final Note? t = await _dao.getNote(templateId);
    final int note = await _dao.createNote(notebookId: notebookId, now: now);
    if (t != null && t.title.isNotEmpty) {
      await _dao.updateNoteTitle(note, t.title, now);
    }
    await _dao.insertBlocksAt(note, 0, await _copyCompanions(templateId));
    return note;
  }

  /// Inserts a template's blocks into an existing note, after [afterOrderIndex]
  /// (photos duplicated). Pass -1 to insert at the very top.
  Future<void> insertTemplateInto(
      int templateId, int targetNoteId, int afterOrderIndex,
      {required DateTime now}) async {
    await _dao.insertBlocksAt(
        targetNoteId, afterOrderIndex + 1, await _copyCompanions(templateId));
    await _dao.touchNote(targetNoteId, now);
  }

  /// Deletes a note and every image file its photo blocks referenced (gather
  /// filenames BEFORE the row delete, since CASCADE removes the block rows).
  Future<void> deleteNoteWithPhotos(int noteId) async {
    final List<NoteBlock> blocks = await _dao.getBlocks(noteId);
    for (final NoteBlock b in blocks) {
      if (b.type == NoteBlockType.photo.storageKey && b.content != null) {
        await _images.delete(b.content!);
      }
    }
    await _dao.deleteNote(noteId);
  }
}
