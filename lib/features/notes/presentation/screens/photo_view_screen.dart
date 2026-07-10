import 'dart:io';

import 'package:flutter/material.dart';

/// Full-screen, pinch-to-zoom viewer for a single note photo.
class PhotoViewScreen extends StatelessWidget {
  const PhotoViewScreen({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
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
