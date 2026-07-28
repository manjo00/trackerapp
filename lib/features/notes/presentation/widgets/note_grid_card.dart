import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/images/image_storage_service.dart';
import '../../domain/note_preview.dart';

/// One note as a Samsung-style portrait card: a photo header (the note's first
/// photo) over a title + snippet + footer. With no usable photo it falls back to
/// a solid cover tinted with the notebook's colour and a big faint note icon.
class NoteGridCard extends StatelessWidget {
  const NoteGridCard({
    required this.note,
    required this.onTap,
    required this.preview,
    required this.accentColorValue,
    this.images,
    super.key,
  });

  final Note note;
  final VoidCallback onTap;
  final NotePreview preview;
  final int accentColorValue;
  final ImageStorageService? images;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;
    final bool untitled = note.title.trim().isEmpty;
    final Color accent = Color(accentColorValue);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _header(context, accent, cs)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    untitled ? 'Untitled' : note.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontStyle: untitled ? FontStyle.italic : null,
                      color:
                          untitled ? cs.onSurface.withAlpha(130) : cs.onSurface,
                    ),
                  ),
                  if (preview.snippet.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      preview.snippet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurface.withAlpha(140)),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _relativeDate(note.updatedAt),
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurface.withAlpha(110)),
                      ),
                      const Spacer(),
                      if (preview.photoCount > 0) ...[
                        Icon(Icons.photo_outlined,
                            size: 13, color: cs.onSurface.withAlpha(120)),
                        const SizedBox(width: 3),
                        Text(
                          '${preview.photoCount}',
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurface.withAlpha(120)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Photo header, or a colored cover when there is no usable photo.
  Widget _header(BuildContext context, Color accent, ColorScheme cs) {
    final String? filename = preview.firstPhotoFilename;
    if (filename == null || filename.isEmpty) {
      return _cover(accent);
    }
    final ImageStorageService store = images ?? ImageStorageService();
    return FutureBuilder<String>(
      future: store.resolvePath(filename),
      builder: (context, snap) {
        final String? path = snap.data;
        if (path == null) return _cover(accent);
        if (!File(path).existsSync()) return _cover(accent);
        return Image.file(File(path), fit: BoxFit.cover);
      },
    );
  }

  /// Solid notebook-tinted cover with a big faint note glyph.
  Widget _cover(Color accent) {
    return Container(
      color: Color.alphaBlend(accent.withAlpha(46), const Color(0x22000000)),
      alignment: Alignment.center,
      child: Icon(
        Icons.sticky_note_2_outlined,
        size: 40,
        color: accent.withAlpha(140),
      ),
    );
  }

  static String _relativeDate(DateTime d) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(d.year, d.month, d.day);
    final int diff = today.difference(day).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    const List<String> m = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${m[d.month]}';
  }
}
