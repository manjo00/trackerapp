import '../../../core/database/app_database.dart';
import '../data/models/note_block_type.dart';

/// The three things a note-grid card needs, derived from a note's blocks:
/// the first photo's filename (for the thumbnail), a one-line text snippet,
/// and the total photo count. Pure — no I/O — so it is unit-testable.
class NotePreview {
  const NotePreview({
    required this.firstPhotoFilename,
    required this.snippet,
    required this.photoCount,
  });

  final String? firstPhotoFilename;
  final String snippet;
  final int photoCount;
}

/// Derives a [NotePreview] from a note's ordered [blocks].
///
/// - snippet = the first non-empty text/checkbox block, trimmed.
/// - firstPhotoFilename = the photo the user chose as cover ([coverBlockId]),
///   or else the first photo block's stored filename (or null). A chosen cover
///   whose block no longer exists — the photo was removed — is ignored, so the
///   card quietly falls back rather than showing a broken image.
/// - photoCount = number of photo blocks.
NotePreview notePreview(List<NoteBlock> blocks, {int? coverBlockId}) {
  String? firstPhoto;
  String? chosenCover;
  String snippet = '';
  int photoCount = 0;

  for (final NoteBlock b in blocks) {
    final NoteBlockType kind = NoteBlockType.parse(b.type);
    if (kind == NoteBlockType.divider) continue; // no content, not a photo
    if (kind == NoteBlockType.photo) {
      photoCount++;
      firstPhoto ??= b.content;
      if (coverBlockId != null && b.id == coverBlockId) chosenCover = b.content;
    } else if (snippet.isEmpty) {
      final String text = (b.content ?? '').trim();
      if (text.isNotEmpty) snippet = text;
    }
  }

  return NotePreview(
    firstPhotoFilename: chosenCover ?? firstPhoto,
    snippet: snippet,
    photoCount: photoCount,
  );
}
