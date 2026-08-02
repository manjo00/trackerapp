import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../providers/home_blocks_providers.dart';

/// Bottom-sheet chooser over every active note (newest-edited first).
/// Returns the picked note, or null if dismissed. Used when adding a
/// pinned-note block and when re-pointing one at a different note.
Future<Note?> showNotePicker(BuildContext context, WidgetRef ref) {
  final List<Note> notes = ref.read(allNotesProvider).valueOrNull ?? const [];
  return showModalBottomSheet<Note>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      if (notes.isEmpty) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No notes yet — create one in Notes first.'),
          ),
        );
      }
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final Note n in notes)
              ListTile(
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: Text(
                  n.title.trim().isEmpty ? 'Untitled' : n.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.of(ctx).pop(n),
              ),
          ],
        ),
      );
    },
  );
}
