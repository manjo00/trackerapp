import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../domain/note_search.dart';
import '../../domain/note_sort.dart';
import '../../../archive/presentation/archive_providers.dart';
import '../providers/notes_providers.dart';
import '../widgets/notebook_form_dialog.dart';
import '../widgets/notebook_tile.dart';
import '../../../coach/data/coach_tip.dart';
import '../../../coach/presentation/coach_controller.dart';
import '../../../coach/presentation/coach_target.dart';

/// Top level of the Notes feature: a search field, a fixed "Unfiled" entry,
/// Templates, then the user's notebooks. FAB creates a notebook.
///
/// Typing in the search field replaces the list with results from **inside**
/// every note, not just their titles — most notes are written straight into
/// the body, so titles alone would find almost nothing.
///
/// Notebooks sort the same four ways notes do (the sort button), and holding a
/// notebook row opens its action sheet — the same gesture as holding a note
/// card, so one habit covers both screens.
class NotesOverviewScreen extends ConsumerStatefulWidget {
  const NotesOverviewScreen({super.key});

  @override
  ConsumerState<NotesOverviewScreen> createState() =>
      _NotesOverviewScreenState();
}

class _NotesOverviewScreenState extends ConsumerState<NotesOverviewScreen> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String query = _search.text;
    final bool searching = query.trim().isNotEmpty;
    final NoteSort sort =
        NoteSort.fromKey(ref.watch(settingsProvider).notebooksSort);

    return CoachMarks(
      screen: kCoachNotes,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notes'),
          actions: [
            if (!searching)
              CoachTarget(
                id: 'notes.sort',
                child: PopupMenuButton<NoteSort>(
                  icon: const Icon(Icons.sort_rounded),
                  tooltip: 'Sort notebooks',
                  initialValue: sort,
                  onSelected: (NoteSort s) => ref
                      .read(settingsProvider.notifier)
                      .setNotebooksSort(s.key),
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
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: CoachTarget(
                id: 'notes.search',
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search notes and what is in them…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: searching
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                ),
              ),
            ),
          ),
        ),
        body: searching ? _results(query, cs) : _browse(cs, sort),
        floatingActionButton: searching
            ? null
            : FloatingActionButton(
                heroTag: 'notes_overview_fab',
                onPressed: _createNotebook,
                child: const Icon(Icons.add_rounded),
              ),
      ),
    );
  }

  // ── Browsing ───────────────────────────────────────────────────────────────

  Widget _browse(ColorScheme cs, NoteSort sort) {
    final List<Notebook> notebooks = sortNotebooks(
      ref.watch(notebooksProvider).valueOrNull ?? const [],
      sort,
      ref.watch(lastNoteEditByNotebookProvider).valueOrNull ?? const {},
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        // Fixed Unfiled bucket (notebookId NULL notes).
        NotebookTile(
          icon: '📥',
          name: 'Unfiled',
          color: cs.primary,
          onTap: () => context.push('/notes/notebook/unfiled'),
        ),
        const SizedBox(height: 4),
        // Reusable templates.
        NotebookTile(
          icon: '📄',
          name: 'Templates',
          color: cs.tertiary,
          onTap: () => context.push('/notes/templates'),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 0, 6),
          child: Text(
            'NOTEBOOKS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
          ),
        ),
        if (notebooks.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Center(
              child: Text(
                'No notebooks yet — tap + to make one',
                style: TextStyle(color: cs.onSurface.withAlpha(140)),
              ),
            ),
          ),
        ...notebooks.map((Notebook nb) => NotebookTile(
              icon: nb.icon,
              name: nb.name,
              color: Color(nb.colorValue),
              starred: nb.isFavorite,
              onTap: () => context.push('/notes/notebook/${nb.id}'),
              onLongPress: () => _showNotebookActions(nb),
            )),
      ],
    );
  }

  // ── Notebook action sheet ──────────────────────────────────────────────────

  Future<void> _showNotebookActions(Notebook nb) async {
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
                  nb.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(nb.isFavorite
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded),
              title: Text(nb.isFavorite ? 'Unstar' : 'Star'),
              onTap: () => Navigator.of(ctx).pop('favorite'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename / recolor'),
              onTap: () => Navigator.of(ctx).pop('rename'),
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive'),
              onTap: () => Navigator.of(ctx).pop('archive'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Delete'),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    final dao = ref.read(notesDaoProvider);
    switch (action) {
      case 'favorite':
        await dao.setNotebookFavorite(nb.id, !nb.isFavorite);
      case 'rename':
        final (String, int, String)? result = await showNotebookFormDialog(
          context,
          title: 'Edit notebook',
          initialName: nb.name,
          initialColor: nb.colorValue,
          initialIcon: nb.icon,
        );
        if (result != null) {
          await dao.renameNotebook(nb.id, result.$1, result.$2, result.$3);
        }
      // Takes the notebook's notes with it (shared timestamp) and brings
      // exactly those back on Undo — see ArchiveService.archiveNotebook.
      case 'archive':
        final ArchiveService svc = ref.read(archiveServiceProvider);
        await svc.archiveNotebook(nb.id, DateTime.now());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${nb.name}" archived'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
              label: 'Undo', onPressed: () => svc.restoreNotebook(nb.id)),
        ));
      case 'delete':
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext c) => AlertDialog(
            title: Text('Delete "${nb.name}"?'),
            content: const Text(
                'The notebook and its notes move to Recently deleted — you '
                'can restore them for 30 days.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(c).pop(false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.of(c).pop(true),
                  child: const Text('Delete')),
            ],
          ),
        );
        if (confirmed == true) {
          await ref
              .read(archiveServiceProvider)
              .trashNotebook(nb.id, DateTime.now());
        }
    }
  }

  // ── Searching ──────────────────────────────────────────────────────────────

  Widget _results(String query, ColorScheme cs) {
    final List<NoteSearchItem> hits =
        searchNotes(ref.watch(noteSearchItemsProvider), query);

    if (hits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No note mentions "${query.trim()}"',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurface.withAlpha(150)),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: hits.length,
      itemBuilder: (BuildContext context, int i) {
        final NoteSearchItem hit = hits[i];
        // The line that matched, when the match was inside the note — so it is
        // obvious why a result turned up before you open it.
        final String? line = noteMatchLine(hit, query);
        return ListTile(
          leading: Icon(Icons.sticky_note_2_outlined,
              color: cs.onSurface.withAlpha(150)),
          title: Text(hit.displayTitle, maxLines: 1,
              overflow: TextOverflow.ellipsis),
          subtitle: Text(
            line == null ? hit.notebookName : '${hit.notebookName}  ·  $line',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: cs.onSurface.withAlpha(150)),
          ),
          onTap: () => context.push('/notes/${hit.id}'),
        );
      },
    );
  }

  Future<void> _createNotebook() async {
    final (String, int, String)? result = await showNotebookFormDialog(
      context,
      title: 'New notebook',
    );
    if (result == null) return;
    await ref.read(notesDaoProvider).createNotebook(
          name: result.$1,
          colorValue: result.$2,
          icon: result.$3,
          now: DateTime.now(),
        );
  }
}
