import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/note_preview.dart';
import '../providers/notes_providers.dart';
import '../widgets/note_grid_card.dart';
import '../widgets/notebook_form_dialog.dart';
import '../../../coach/data/coach_tip.dart';
import '../../../coach/presentation/coach_controller.dart';

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

    return CoachMarks(
      screen: kCoachNotebook,
      child: Scaffold(
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
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: notes.length,
              itemBuilder: (context, i) => _NoteRow(
                note: notes[i],
                accentColorValue:
                    notebook?.colorValue ?? cs.primary.toARGB32(),
                onTap: () => context.push('/notes/${notes[i].id}'),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notebook_detail_fab',
        onPressed: () => _createNote(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    ));
  }

  Future<void> _createNote(BuildContext context, WidgetRef ref) async {
    final dao = ref.read(notesDaoProvider);
    final List<Note> templates =
        ref.read(templatesProvider).valueOrNull ?? const [];

    // No templates → straight to a blank note (original behaviour).
    if (templates.isEmpty) {
      final int id =
          await dao.createNote(notebookId: notebookId, now: DateTime.now());
      if (context.mounted) context.push('/notes/$id');
      return;
    }

    // Otherwise offer Blank or a template. -1 = blank.
    final int? pick = await showModalBottomSheet<int>(
      context: context,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.note_add_rounded),
              title: const Text('Blank note'),
              onTap: () => Navigator.of(c).pop(-1),
            ),
            const Divider(height: 1),
            for (final Note t in templates)
              ListTile(
                leading: const Icon(Icons.dashboard_customize_rounded),
                title: Text(
                    t.title.trim().isEmpty ? 'Untitled template' : t.title),
                onTap: () => Navigator.of(c).pop(t.id),
              ),
          ],
        ),
      ),
    );
    if (pick == null) return; // cancelled

    final int id = pick == -1
        ? await dao.createNote(notebookId: notebookId, now: DateTime.now())
        : await ref.read(notesRepositoryProvider).newNoteFromTemplate(pick,
            notebookId: notebookId, now: DateTime.now());
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

/// A note card that derives its preview (first photo, snippet, count) from the
/// note's blocks and renders a [NoteGridCard].
class _NoteRow extends ConsumerWidget {
  const _NoteRow({
    required this.note,
    required this.onTap,
    required this.accentColorValue,
  });

  final Note note;
  final VoidCallback onTap;
  final int accentColorValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<NoteBlock> blocks =
        ref.watch(noteBlocksProvider(note.id)).valueOrNull ?? const [];
    return NoteGridCard(
      note: note,
      onTap: onTap,
      preview: notePreview(blocks),
      accentColorValue: accentColorValue,
      images: ref.watch(imageStorageServiceProvider),
    );
  }
}
