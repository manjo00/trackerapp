import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../archive/presentation/archive_providers.dart';
import '../providers/notes_providers.dart';

/// Lists the user's note templates. Each opens in the normal block editor
/// (a template is just a note with isTemplate = true). The FAB makes a new
/// blank template.
class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<Note> templates =
        ref.watch(templatesProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Templates')),
      body: templates.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No templates yet.\nTap + to build one, or use "Save as '
                  'template" from any note.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurface.withAlpha(140)),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              children: [
                for (final Note t in templates)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.dashboard_customize_rounded),
                      title: Text(
                        t.title.trim().isEmpty ? 'Untitled template' : t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.title.trim().isEmpty
                            ? TextStyle(
                                fontStyle: FontStyle.italic,
                                color: cs.onSurface.withAlpha(140))
                            : null,
                      ),
                      onTap: () => context.push('/notes/${t.id}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        tooltip: 'Delete template',
                        onPressed: () => _delete(context, ref, t),
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'templates_fab',
        onPressed: () => _newTemplate(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _newTemplate(BuildContext context, WidgetRef ref) async {
    final int id = await ref
        .read(notesDaoProvider)
        .createNote(now: DateTime.now(), isTemplate: true);
    if (context.mounted) context.push('/notes/$id');
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Note t) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete "${t.title.trim().isEmpty ? 'Untitled' : t.title}"?'),
        content: const Text('The template moves to Recently deleted for 30 days. '
            'Notes made from it stay.'),
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
    if (ok == true) {
      await ref.read(archiveServiceProvider).trashNote(t.id, DateTime.now());
    }
  }
}
