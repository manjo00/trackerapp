import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/task_model.dart';
import '../providers/tasks_providers.dart';
import '../widgets/empty_tasks_placeholder.dart';
import '../widgets/task_tile.dart';

/// All-tasks tab.
///
/// Watches [allTasksProvider] (a StreamProvider). The repository already
/// delivers tasks sorted: incomplete first → due date asc → priority desc.
/// This screen splits the list at the first completed task and inserts a
/// "Completed" section header between the two groups.
class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<TaskModel>> tasksAsync =
        ref.watch(allTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      body: tasksAsync.when(
        // ── Loading ────────────────────────────────────────────────────────
        loading: () => const Center(child: CircularProgressIndicator()),

        // ── Error ──────────────────────────────────────────────────────────
        error: (Object err, StackTrace _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Something went wrong:\n$err',
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // ── Data ───────────────────────────────────────────────────────────
        data: (List<TaskModel> tasks) {
          if (tasks.isEmpty) {
            return const EmptyTasksPlaceholder();
          }

          // Split into incomplete / completed.
          // The list is already sorted with incomplete tasks first, so we
          // just find the index of the first completed task.
          final int splitIndex =
              tasks.indexWhere((TaskModel t) => t.isCompleted);
          final bool hasCompleted = splitIndex != -1;

          // Build a flat item list that the ListView understands.
          // Each entry is either a TaskModel or the sentinel _sectionHeader.
          //
          // Example with 2 incomplete + 1 completed:
          //   [task0, task1, _sectionHeader, task2]
          //
          // indexWhere returns -1 if no completed tasks exist.
          final List<Object> items = [
            if (splitIndex == -1)
              // All tasks are incomplete — no header needed.
              ...tasks
            else ...[
              ...tasks.sublist(0, splitIndex), // incomplete
              _sectionHeader,                  // divider sentinel
              ...tasks.sublist(splitIndex),    // completed
            ],
          ];

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            itemCount: items.length,
            itemBuilder: (BuildContext context, int index) {
              final Object item = items[index];

              // ── Section header ─────────────────────────────────────────
              if (item == _sectionHeader) {
                return _CompletedHeader(
                  count: hasCompleted
                      ? tasks.length - splitIndex
                      : 0,
                );
              }

              // ── Task tile ──────────────────────────────────────────────
              return TaskTile(task: item as TaskModel);
            },
          );
        },
      ),

      // ── FAB ─────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tasks/add'),
        tooltip: 'Add task',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// Private sentinel object — used as a type-safe placeholder in the items list
// to indicate where the "Completed" section header should be rendered.
const Object _sectionHeader = _SectionHeaderSentinel();

class _SectionHeaderSentinel {
  const _SectionHeaderSentinel();
}

// ── Completed section header ──────────────────────────────────────────────────

class _CompletedHeader extends StatelessWidget {
  const _CompletedHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Text(
            'Completed',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurface.withAlpha(120),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: cs.onSurface.withAlpha(18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withAlpha(120),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
