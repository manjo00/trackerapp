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

  /// Removes a photo block and deletes its backing file.
  Future<void> removePhotoBlock(NoteBlock block, {required DateTime now}) async {
    final String? filename = block.content;
    if (filename != null && filename.isNotEmpty) {
      await _images.delete(filename);
    }
    await _dao.deleteBlock(block.id);
    await _dao.touchNote(block.noteId, now);
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
