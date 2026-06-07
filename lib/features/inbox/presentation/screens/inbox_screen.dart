import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/providers/tasks_providers.dart';
import '../../../tasks/presentation/widgets/task_tile.dart';

/// The Inbox tab — shows incomplete tasks with no due date.
///
/// These are items the user captured quickly without scheduling them.
/// The inbox is the "process later" bucket: assign a date to move them
/// to the calendar / Today view, or check them off in-place.
///
/// A quick-capture FAB opens [AddTaskScreen] with no pre-filled date.
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(inboxTasksProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: inboxAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (List<TaskModel> tasks) {
          if (tasks.isEmpty) {
            return _EmptyInbox(onAdd: () => context.push('/tasks/add'));
          }
          return ListView(
            padding: const EdgeInsets.only(top: 4, bottom: 96),
            children: [
              // Count chip
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${tasks.length} unscheduled',
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '· tap to schedule',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withAlpha(120)),
                    ),
                  ],
                ),
              ),
              ...tasks.map((t) => TaskTile(task: t)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'inbox_fab',
        onPressed: () => context.push('/tasks/add'),
        tooltip: 'Quick add',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded,
                size: 64, color: cs.onSurface.withAlpha(60)),
            const SizedBox(height: 16),
            Text(
              'Inbox is empty',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tasks without a due date land here.\nSchedule them or check them off.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withAlpha(140),
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add task'),
            ),
          ],
        ),
      ),
    );
  }
}
