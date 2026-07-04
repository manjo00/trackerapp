import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/database/app_database.dart';
import '../providers/lists_providers.dart';
import '../widgets/list_form_dialog.dart';
import 'task_list_screen.dart';

/// The Lists tab: a built-in "All tasks" view (the old flat Tasks screen)
/// followed by the user's lists. Lives inside the shell (no own AppBar).
class ListsOverviewScreen extends ConsumerWidget {
  const ListsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<List<TaskList>> listsAsync = ref.watch(taskListsProvider);
    final Map<int, int> counts =
        ref.watch(listTaskCountsProvider).valueOrNull ?? const {};

    return Scaffold(
      body: listsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, StackTrace _) =>
            Center(child: Text('Something went wrong:\n$err')),
        data: (List<TaskList> lists) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            // ── Built-in flat view ─────────────────────────────────────
            Card(
              child: ListTile(
                leading: Icon(Icons.checklist_rounded, color: cs.primary),
                title: const Text('All tasks'),
                subtitle: const Text('Every task, flat view'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('All tasks')),
                      body: const TaskListScreen(),
                    ),
                  ),
                ),
              ),
            ),

            if (lists.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
                child: Text(
                  kListNounPlural.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                ),
              ),
              ...lists.map(
                (TaskList list) => Card(
                  child: ListTile(
                    leading: Icon(Icons.circle,
                        size: 16, color: Color(list.colorValue)),
                    title: Text(list.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if ((counts[list.id] ?? 0) > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${counts[list.id]}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                    onTap: () => context.push('/lists/${list.id}'),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 48),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.folder_copy_outlined,
                        size: 56, color: cs.onSurface.withAlpha(60)),
                    const SizedBox(height: 12),
                    Text(
                      'No ${kListNounPlural.toLowerCase()} yet',
                      style: TextStyle(color: cs.onSurface.withAlpha(140)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Group tasks into a ${kListNoun.toLowerCase()} with sections',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurface.withAlpha(100)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'lists_overview_fab',
        onPressed: () async {
          final (String, int)? result = await showListFormDialog(
            context,
            title: 'New $kListNoun',
            hintText: 'e.g. Kitchen renovation',
          );
          if (result == null) return;
          await ref
              .read(listsRepositoryProvider)
              .addList(result.$1, result.$2);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New $kListNoun'),
      ),
    );
  }
}
