import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../domain/note_preview.dart';
import '../../domain/note_sort.dart';
import '../../../archive/presentation/archive_providers.dart';
import '../providers/notes_providers.dart';
import '../widgets/note_grid_card.dart';
import '../widgets/notebook_form_dialog.dart';
import '../widgets/notebook_picker_sheet.dart';
import '../../../coach/data/coach_tip.dart';
import '../../../coach/presentation/coach_controller.dart';
import '../../../coach/presentation/coach_target.dart';

/// One notebook's notes as a photo grid. [notebookId] null = Unfiled.
///
/// The sort button orders the grid (last edited · created · name · starred
/// first — one setting shared by every notebook). Holding a card opens its
/// action sheet: star, move to another notebook, duplicate, archive — the same
/// gesture as holding an app on the home screen, so nothing has to be learnt.
class NotebookDetailScreen extends ConsumerWidget {
  const NotebookDetailScreen({required this.notebookId, super.key});

  final int? notebookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    final List<Notebook> notebooks =
        ref.watch(notebooksProvider).valueOrNull ?? const [];
    final Notebook? notebook = notebookId == null
        ? null
        : notebooks.where((n) => n.id == notebookId).firstOrNull;
    final String title =
        notebookId == null ? 'Unfiled' : (notebook?.name ?? '…');

    final NoteSort sort = NoteSort.fromKey(ref.watch(settingsProvider).notesSort);
    final List<Note> notes = sortNotes(
      ref.watch(notesForNotebookProvider(notebookId)).valueOrNull ?? const [],
      sort,
    );

    return CoachMarks(
      screen: kCoachNotebook,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            CoachTarget(
              id: 'notebook.sort',
              child: PopupMenuButton<NoteSort>(
              icon: const Icon(Icons.sort_rounded),
              tooltip: 'Sort',
              initialValue: sort,
              onSelected: (NoteSort s) =>
                  ref.read(settingsProvider.notifier).setNotesSort(s.key),
              itemBuilder: (BuildContext context) => [
                for (final NoteSort s in NoteSort.values)
                  CheckedPopupMenuItem<NoteSort>(
                    value: s,
                    checked: s == sort,
                    child: Text(s.label),
                  ),
              ],
              ),
            ),
            // Unfiled is a virtual bucket — no rename/archive/delete for it.
            if (notebook != null)
              PopupMenuButton<String>(
                onSelected: (String a) => _onAction(context, ref, a, notebook),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                      value: 'rename', child: Text('Rename / recolor')),
                  PopupMenuItem(value: 'archive', child: Text('Archive')),
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
                  onLongPress: () =>
                      _showCardActions(context, ref, notes[i], notebooks),
                ),
              ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'notebook_detail_fab',
          onPressed: () => _createNote(context, ref),
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  // ── Card action sheet ──────────────────────────────────────────────────────

  Future<void> _showCardActions(
    BuildContext context,
    WidgetRef ref,
    Note note,
    List<Notebook> notebooks,
  ) async {
    final String? action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  note.title.trim().isEmpty ? 'Untitled note' : note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(note.isFavorite
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded),
              title: Text(note.isFavorite ? 'Unstar' : 'Star'),
              onTap: () => Navigator.of(ctx).pop('favorite'),
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_move_outline),
              title: const Text('Move to…'),
              onTap: () => Navigator.of(ctx).pop('move'),
            ),
            ListTile(
              leading: const Icon(Icons.content_copy_rounded),
              title: const Text('Duplicate'),
              onTap: () => Navigator.of(ctx).pop('duplicate'),
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive'),
              onTap: () => Navigator.of(ctx).pop('archive'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    final dao = ref.read(notesDaoProvider);
    switch (action) {
      case 'favorite':
        await dao.setNoteFavorite(note.id, !note.isFavorite);
      case 'move':
        final NotebookChoice? choice = await showNotebookPickerSheet(
          context,
          notebooks: notebooks,
          currentNotebookId: note.notebookId,
        );
        if (choice == null) return;
        await dao.moveNote(note.id, choice.notebookId, DateTime.now());
        if (!context.mounted) return;
        final String where = choice.notebookId == null
            ? 'Unfiled'
            : notebooks
                    .where((n) => n.id == choice.notebookId)
                    .firstOrNull
                    ?.name ??
                'that notebook';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Moved to $where'),
          duration: const Duration(seconds: 2),
        ));
      case 'duplicate':
        final int copy = await ref
            .read(notesRepositoryProvider)
            .duplicateNote(note.id, now: DateTime.now());
        if (context.mounted) context.push('/notes/$copy');
      case 'archive':
        // Reversible, so no confirm — the snackbar's Undo is the safety net.
        final ArchiveService svc = ref.read(archiveServiceProvider);
        await svc.archiveNote(note.id, DateTime.now());
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Note archived'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
              label: 'Undo', onPressed: () => svc.restoreNote(note.id)),
        ));
    }
  }

  // ── Creating a note ────────────────────────────────────────────────────────

  Future<void> _createNote(BuildContext context, WidgetRef ref) async {
    final dao = ref.read(notesDaoProvider);
    // Starred templates first, matching the Templates screen.
    final List<Note> templates = sortNotes(
      ref.read(templatesProvider).valueOrNull ?? const [],
      NoteSort.starred,
    );

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
                leading: Icon(t.isFavorite
                    ? Icons.star_rounded
                    : Icons.dashboard_customize_rounded),
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

  // ── Notebook menu ──────────────────────────────────────────────────────────

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
      // Archiving takes the notebook's notes with it (same timestamp), so a
      // full notebook doesn't scatter its notes into Unfiled — and restoring
      // brings back exactly what went in.
      case 'archive':
        final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
        final ArchiveService svc = ref.read(archiveServiceProvider);
        await svc.archiveNotebook(nb.id, DateTime.now());
        messenger.showSnackBar(SnackBar(
          content: Text('"${nb.name}" archived'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
              label: 'Undo', onPressed: () => svc.restoreNotebook(nb.id)),
        ));
        if (context.mounted) context.pop();
      case 'delete':
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete "${nb.name}"?'),
            content: const Text(
                'The notebook and its notes move to Recently deleted — you '
                'can restore them for 30 days.'),
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
          await ref
              .read(archiveServiceProvider)
              .trashNotebook(nb.id, DateTime.now());
          if (context.mounted) context.pop();
        }
    }
  }
}

/// A note card that derives its preview (cover photo, snippet, count) from the
/// note's blocks and renders a [NoteGridCard].
class _NoteRow extends ConsumerWidget {
  const _NoteRow({
    required this.note,
    required this.onTap,
    required this.onLongPress,
    required this.accentColorValue,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final int accentColorValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<NoteBlock> blocks =
        ref.watch(noteBlocksProvider(note.id)).valueOrNull ?? const [];
    return NoteGridCard(
      note: note,
      onTap: onTap,
      onLongPress: onLongPress,
      preview: notePreview(blocks, coverBlockId: note.coverBlockId),
      accentColorValue: accentColorValue,
      images: ref.watch(imageStorageServiceProvider),
    );
  }
}
