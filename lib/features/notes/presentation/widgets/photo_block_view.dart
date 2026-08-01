import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../providers/notes_providers.dart';
import '../screens/photo_view_screen.dart';

/// Max inline height for a note photo (A1). Taller images are scaled down
/// (aspect kept, no crop) so no single photo dominates the scroll; tapping
/// opens the full-resolution image full-screen. Tunable on device.
const double kNotePhotoMaxHeight = 220;

/// Renders a photo block inline: the image (tap → full-screen) with a remove
/// button, or a tidy "unavailable" placeholder when the file is gone (e.g.
/// after a restore on a fresh device — the JSON backup carries no image bytes).
class PhotoBlockView extends ConsumerWidget {
  const PhotoBlockView({
    required this.block,
    required this.onRemove,
    this.onCrop,
    super.key,
  });

  final NoteBlock block;
  final VoidCallback onRemove;
  final VoidCallback? onCrop;

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
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxHeight: kNotePhotoMaxHeight),
                          child: Image.file(
                            File(path),
                            width: double.infinity,
                            fit: BoxFit.contain,
                          ),
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
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onCrop != null && exists) ...[
                      _circleButton(Icons.crop_rotate_rounded, onCrop!),
                      const SizedBox(width: 6),
                    ],
                    _circleButton(Icons.close_rounded, onRemove),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// A small translucent circular icon button for the photo overlay.
  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 15, color: Colors.white),
        ),
      ),
    );
  }
}
