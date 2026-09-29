import 'dart:io';

import 'package:flutter/material.dart';

/// Full-screen, pinch-to-zoom viewer for a single note photo.
///
/// When opened from a note, [onUseAsCover] puts a star in the bar: this is
/// the moment you are looking at the photo full-size, which is when you
/// decide it should be the one on the card. [isCover] shows it filled when
/// this photo already is.
class PhotoViewScreen extends StatelessWidget {
  const PhotoViewScreen({
    required this.path,
    this.onUseAsCover,
    this.isCover = false,
    super.key,
  });

  final String path;
  final VoidCallback? onUseAsCover;
  final bool isCover;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? useAsCover = onUseAsCover;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (useAsCover != null)
            IconButton(
              icon: Icon(isCover ? Icons.star_rounded : Icons.star_outline_rounded),
              tooltip: isCover ? 'This is the cover' : 'Use as cover',
              onPressed: isCover
                  ? null
                  : () {
                      useAsCover();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Set as the cover photo'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
            ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Image.file(File(path)),
        ),
      ),
    );
  }
}
