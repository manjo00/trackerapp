import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/task_model.dart';
import '../providers/tasks_providers.dart';
import 'priority_badge.dart';

/// A card representing one task in the list.
///
/// Interactions:
///   • Tap anywhere   → toggle completion
///   • Long-press     → open edit screen (pre-filled)
///   • Swipe left     → delete with undo snackbar
class TaskTile extends ConsumerWidget {
  const TaskTile({required this.task, super.key});

  final TaskModel task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool done = task.isCompleted;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      // Red background with trash icon revealed on left-swipe.
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_rounded, color: cs.onErrorContainer),
      ),
      onDismissed: (_) => _delete(context, ref),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggle(ref),
          onLongPress: () => context.push('/tasks/edit', extra: task),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Checkbox ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: GestureDetector(
                    onTap: () => _toggle(ref),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? cs.primary : Colors.transparent,
                        border: Border.all(
                          color: done ? cs.primary : cs.outline,
                          width: 2,
                        ),
                      ),
                      child: done
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // ── Text content ─────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task.title,
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: done
                                      ? cs.onSurface.withAlpha(130)
                                      : cs.onSurface,
                                ),
                      ),

                      // Note preview (first line only)
                      if (task.note != null && task.note!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withAlpha(100),
                          ),
                        ),
                      ],

                      // Due date chip (only shown when set)
                      if (task.dueDate != null) ...[
                        const SizedBox(height: 4),
                        _DueDateChip(dueDate: task.dueDate!, done: done),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── Priority badge ───────────────────────────────────────────
                if (!done) PriorityBadge(priority: task.priority),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggle(WidgetRef ref) {
    ref.read(toggleTaskProvider.notifier).toggle(
          task.id,
          currentlyCompleted: task.isCompleted,
        );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    await ref.read(deleteTaskProvider.notifier).delete(task.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${task.title}" deleted'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// ── Due date chip ─────────────────────────────────────────────────────────────

class _DueDateChip extends StatelessWidget {
  const _DueDateChip({required this.dueDate, required this.done});

  final String dueDate; // "yyyy-MM-dd"
  final bool done;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool overdue = _isOverdue(dueDate);

    final Color color = done
        ? cs.onSurface.withAlpha(80)
        : overdue
            ? cs.error
            : cs.onSurface.withAlpha(140);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today_rounded, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          _formatDate(dueDate),
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  bool _isOverdue(String date) {
    final DateTime today = DateTime.now();
    final DateTime due = DateTime.parse(date);
    return due.isBefore(DateTime(today.year, today.month, today.day));
  }

  String _formatDate(String date) {
    final DateTime today = DateTime.now();
    final DateTime due = DateTime.parse(date);
    final DateTime todayDate = DateTime(today.year, today.month, today.day);
    final DateTime dueDate = DateTime(due.year, due.month, due.day);
    final int diff = dueDate.difference(todayDate).inDays;

    return switch (diff) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      _ when diff < 0 => '${-diff}d overdue',
      _ => '${due.day} ${_monthAbbr(due.month)}',
    };
  }

  String _monthAbbr(int month) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][month];
}
