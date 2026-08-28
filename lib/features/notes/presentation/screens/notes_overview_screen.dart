import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/note_search.dart';
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

    return CoachMarks(
      screen: kCoachNotes,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notes'),
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
        body: searching ? _results(query, cs) : _browse(cs),
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

  Widget _browse(ColorScheme cs) {
    final List<Notebook> notebooks =
        ref.watch(notebooksProvider).valueOrNull ?? const [];

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
              onTap: () => context.push('/notes/notebook/${nb.id}'),
            )),
      ],
    );
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
