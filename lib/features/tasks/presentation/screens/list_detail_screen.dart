import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/github/github_feedback_providers.dart';
import '../../../../core/github/github_feedback_service.dart';
import '../../../../core/github/markdown_feedback_builder.dart';
import '../../data/models/task_model.dart';
import '../providers/lists_providers.dart';
import '../widgets/list_form_dialog.dart';
import '../widgets/task_tile.dart';
import 'add_task_screen.dart';

/// One list, full-screen: unsectioned tasks first, then each section as a
/// header with its tasks. List rename/recolor/delete via the AppBar menu.
class ListDetailScreen extends ConsumerWidget {
  const ListDetailScreen({required this.listId, super.key});

  final int listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    final List<TaskList> lists =
        ref.watch(taskListsProvider).valueOrNull ?? const [];
    final TaskList? list = lists.where((l) => l.id == listId).firstOrNull;
    final List<ListSection> sections =
        ref.watch(sectionsForListProvider(listId)).valueOrNull ?? const [];
    final List<TaskModel> tasks =
        ref.watch(tasksForListProvider(listId)).valueOrNull ?? const [];

    // List was deleted while open (e.g. from another device later) — bail.
    if (list == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Set<int> sectionIds = sections.map((s) => s.id).toSet();
    // Unsectioned = no section, or a stale one that no longer exists.
    final List<TaskModel> unsectioned = tasks
        .where((t) => t.sectionId == null || !sectionIds.contains(t.sectionId))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 14, color: Color(list.colorValue)),
            const SizedBox(width: 10),
            Flexible(child: Text(list.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String action) => action == 'push_github'
                ? _pushToGithub(context, ref, list, sections, tasks)
                : _onListAction(context, ref, action, list),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename / recolor')),
              PopupMenuItem(
                  value: 'push_github', child: Text('Push feedback to GitHub')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (tasks.isEmpty && sections.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Center(
                child: Text(
                  'Nothing here yet — add a task or a section',
                  style: TextStyle(color: cs.onSurface.withAlpha(140)),
                ),
              ),
            ),

          // ── Unsectioned tasks (list body) ──────────────────────────────
          ...unsectioned.map((t) => TaskTile(task: t)),

          // ── Sections ───────────────────────────────────────────────────
          for (final ListSection section in sections) ...[
            _SectionHeader(
              section: section,
              onAddTask: () => context.push(
                '/tasks/add',
                extra: AddTaskArgs(listId: listId, sectionId: section.id),
              ),
              onRename: () => _renameSection(context, ref, section),
              onDelete: () => _deleteSection(context, ref, section),
            ),
            ...tasks
                .where((t) => t.sectionId == section.id)
                .map((t) => TaskTile(task: t)),
          ],

          // ── Add section ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _addSection(context, ref),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add section'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'list_detail_fab',
        onPressed: () =>
            context.push('/tasks/add', extra: AddTaskArgs(listId: listId)),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  // ── List actions ──────────────────────────────────────────────────────────

  Future<void> _onListAction(BuildContext context, WidgetRef ref,
      String action, TaskList list) async {
    final repo = ref.read(listsRepositoryProvider);
    switch (action) {
      case 'rename':
        final (String, int)? result = await showListFormDialog(
          context,
          title: 'Edit $kListNoun',
          initialName: list.name,
          initialColor: list.colorValue,
        );
        if (result != null) {
          await repo.renameList(list.id, result.$1, result.$2);
        }
      case 'delete':
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete "${list.name}"?'),
            content: const Text('Its tasks return to Captured on Home.'),
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
          await repo.deleteList(list.id);
          if (context.mounted) context.pop();
        }
    }
  }

  // ── GitHub push ───────────────────────────────────────────────────────────

  /// Publishes this list as feedback/<slug>.md in the configured repo.
  /// Uses the sections/tasks already loaded by build() — no extra fetch.
  Future<void> _pushToGithub(BuildContext context, WidgetRef ref,
      TaskList list, List<ListSection> sections, List<TaskModel> tasks) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final GoRouter router = GoRouter.of(context);

    final GithubFeedbackService service =
        ref.read(githubFeedbackServiceProvider);
    final GithubFeedbackConfig? config = await service.loadConfig();
    if (config == null) {
      messenger.showSnackBar(SnackBar(
        content: const Text('Set up the GitHub connection first'),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () => router.push('/settings'),
        ),
      ));
      return;
    }

    messenger.showSnackBar(
        const SnackBar(content: Text('Pushing to GitHub…')));

    final String markdown = buildFeedbackMarkdown(
      listName: list.name,
      sections: [for (final s in sections) (id: s.id, name: s.name)],
      tasks: tasks,
      now: DateTime.now(),
    );
    final GithubPushResult result = await service.pushMarkdown(
      config: config,
      path: 'feedback/${slugify(list.name)}.md',
      content: markdown,
      commitMessage: 'feedback: update "${list.name}" from Uplan',
    );

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(result.message)));
  }

  // ── Section actions ───────────────────────────────────────────────────────

  Future<void> _addSection(BuildContext context, WidgetRef ref) async {
    final String? name = await _promptForName(context, 'New section');
    if (name == null || name.isEmpty) return;
    await ref.read(listsRepositoryProvider).addSection(listId, name);
  }

  Future<void> _renameSection(
      BuildContext context, WidgetRef ref, ListSection section) async {
    final String? name =
        await _promptForName(context, 'Rename section', initial: section.name);
    if (name == null || name.isEmpty) return;
    await ref.read(listsRepositoryProvider).renameSection(section.id, name);
  }

  Future<void> _deleteSection(
      BuildContext context, WidgetRef ref, ListSection section) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${section.name}"?'),
        content: Text('Tasks stay in the ${kListNoun.toLowerCase()}.'),
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
      await ref.read(listsRepositoryProvider).deleteSection(section.id);
    }
  }

  static Future<String?> _promptForName(BuildContext context, String title,
      {String initial = ''}) {
    final TextEditingController ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Section name'),
          onSubmitted: (String v) => Navigator.of(context).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── Section header row ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.section,
    required this.onAddTask,
    required this.onRename,
    required this.onDelete,
  });

  final ListSection section;
  final VoidCallback onAddTask;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 0, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              section.name.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_rounded, size: 18),
            tooltip: 'Add task here',
            onPressed: onAddTask,
          ),
          PopupMenuButton<String>(
            iconSize: 18,
            onSelected: (String v) => v == 'rename' ? onRename() : onDelete(),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}
