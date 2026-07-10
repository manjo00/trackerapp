import 'package:flutter/material.dart';

/// Placeholder — the real block editor is built in Task 7.
class NoteEditorScreen extends StatelessWidget {
  const NoteEditorScreen({required this.noteId, super.key});

  final int noteId;

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Editor (Task 7)')));
}
