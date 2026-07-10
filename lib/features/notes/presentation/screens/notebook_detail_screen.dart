import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../data/models/note_block_type.dart';
import '../providers/notes_providers.dart';
import '../widgets/note_tile.dart';
import '../widgets/notebook_form_dialog.dart';

/// One notebook's notes (newest-edited first). [notebookId] null = Unfiled.
class NotebookDetailScreen extends ConsumerWidget {
  const NotebookDetailScreen({required this.notebookId, super.key});

  final int? notebookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    final List<Notebook> notebooks =
        ref.watch(notebooksProvider).valueOrNull ?? const [];
    final Notebook? notebook =
        notebookId == null ? null : notebooks.where((n) => n.id == notebookId).firstOrNull;
    final String title = notebookId == null ? 'Unfiled' : (notebook?.name ?? '…');

    final List<Note> notes =
        ref.watch(notesForNotebookProvider(notebookId)).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // Unfiled is a virtual bucket — no rename/delete for it.
          if (notebook != null)
            PopupMenuButton<String>(
              onSelected: (String a) => _onAction(context, ref, a, notebook),
              itemBuilder: (context) => const [
                PopupMenuItem(
                    value: 'rename', child: Text('Rename / recolor')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
      body: notes.isEmpty
          ? Center(
              child: Text(
                'No notes yet — tap + to write one',
                style: TextStyle(color: cs.onSurface.withAlpha(140)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: notes
                  .map((Note n) => _NoteRow(
                        note: n,
                        onTap: () => context.push('/notes/${n.id}'),
                      ))
                  .toList(),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notebook_detail_fab',
        onPressed: () => _createNote(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _createNote(BuildContext context, WidgetRef ref) async {
    final int id = await ref
        .read(notesDaoProvider)
        .createNote(notebookId: notebookId, now: DateTime.now());
    if (context.mounted) context.push('/notes/$id');
  }

  Future<void> _onAction(
      BuildContext context, WidgetRef ref, String action, Notebook nb) async {
    switch (action) {
      case 'rename':
        final (String, int, String)? result = await showNotebookFormDialog(
          context,
          title: 'Edit notebook',
          initialName: nb.name,
          initialColor: nb.colorValue,
          initialIcon: nb.icon,
        );
        if (result != null) {
          await ref
              .read(notesDaoProvider)
              .renameNotebook(nb.id, result.$1, result.$2, result.$3);
        }
      case 'delete':
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete "${nb.name}"?'),
            content: const Text('Its notes move to Unfiled (not deleted).'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await ref.read(notesDaoProvider).deleteNotebook(nb.id);
          if (context.mounted) context.pop();
        }
    }
  }
}

/// A note row that derives its preview + photo count from the note's blocks.
class _NoteRow extends ConsumerWidget {
  const _NoteRow({required this.note, required this.onTap});

  final Note note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<NoteBlock> blocks =
        ref.watch(noteBlocksProvider(note.id)).valueOrNull ?? const [];

    final String preview = blocks
        .where((b) =>
            b.type != NoteBlockType.photo.storageKey &&
            (b.content ?? '').trim().isNotEmpty)
        .map((b) => b.content!.trim())
        .join(' · ');
    final int photoCount =
        blocks.where((b) => b.type == NoteBlockType.photo.storageKey).length;

    return NoteTile(
      note: note,
      onTap: onTap,
      preview: preview,
      photoCount: photoCount,
    );
  }
}
