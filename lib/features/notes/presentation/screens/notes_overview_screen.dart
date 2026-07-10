import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../providers/notes_providers.dart';
import '../widgets/notebook_form_dialog.dart';
import '../widgets/notebook_tile.dart';

/// Top level of the Notes feature: a fixed "Unfiled" entry followed by the
/// user's notebooks. FAB creates a notebook.
class NotesOverviewScreen extends ConsumerWidget {
  const NotesOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<Notebook> notebooks =
        ref.watch(notebooksProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: ListView(
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
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notes_overview_fab',
        onPressed: () => _createNotebook(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _createNotebook(BuildContext context, WidgetRef ref) async {
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
