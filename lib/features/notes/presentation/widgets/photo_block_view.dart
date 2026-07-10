import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../providers/notes_providers.dart';
import '../screens/photo_view_screen.dart';

/// Renders a photo block inline: the image (tap → full-screen) with a remove
/// button, or a tidy "unavailable" placeholder when the file is gone (e.g.
/// after a restore on a fresh device — the JSON backup carries no image bytes).
class PhotoBlockView extends ConsumerWidget {
  const PhotoBlockView({required this.block, required this.onRemove, super.key});

  final NoteBlock block;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String filename = block.content ?? '';
    final images = ref.watch(imageStorageServiceProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: FutureBuilder<String>(
        future: images.resolvePath(filename),
        builder: (context, snap) {
          final String? path = snap.data;
          if (path == null) {
            return const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final bool exists = filename.isNotEmpty && File(path).existsSync();
          return Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: exists
                    ? GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PhotoViewScreen(path: path),
                          ),
                        ),
                        child: Image.file(
                          File(path),
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                        ),
                      )
                    : Container(
                        height: 110,
                        width: double.infinity,
                        color: cs.surfaceContainerHighest,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_outlined,
                                color: cs.onSurface.withAlpha(120)),
                            const SizedBox(height: 6),
                            Text('Image unavailable',
                                style: TextStyle(
                                    color: cs.onSurface.withAlpha(120),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
