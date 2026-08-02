import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../notes/presentation/providers/notes_providers.dart';
import '../../data/models/task_model.dart';
import '../providers/lists_providers.dart';
import '../providers/tasks_providers.dart';
import 'priority_badge.dart';

/// The note an @time task line came from (via its source block), or null for
/// ordinary tasks / deleted notes. Public so widget tests can override it.
final sourceNoteForTaskProvider =
    FutureProvider.family<Note?, int>((ref, blockId) async {
  final dao = ref.watch(notesDaoProvider);
  final NoteBlock? block = await dao.getBlock(blockId);
  if (block == null) return null;
  return dao.getNote(block.noteId);
});

/// Opens the read-first look at a task: full title/note, due, priority,
/// labels, and where it lives — its list, and the note that spawned it (both
/// tappable). Completing happens on the check circle only; Edit opens the
/// full editor.
Future<void> showTaskDetailSheet(BuildContext context, TaskModel task) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => TaskDetailSheet(task: task),
    );

class TaskDetailSheet extends ConsumerWidget {
  const TaskDetailSheet({required this.task, super.key});

  final TaskModel task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool done = task.isCompleted;

    // Owning list (null listId = Captured, which has no screen of its own).
    final List<TaskList> lists =
        ref.watch(taskListsProvider).valueOrNull ?? const [];
    final TaskList? list = task.listId == null
        ? null
        : lists.where((l) => l.id == task.listId).firstOrNull;

    // Label chips.
    final List<Label> allLabels =
        ref.watch(labelsProvider).valueOrNull ?? const [];
    final List<int> labelIds =
        ref.watch(labelIdsForTaskProvider(task.id)).valueOrNull ?? const [];
    final List<Label> labels =
        allLabels.where((l) => labelIds.contains(l.id)).toList();

    // Source note, when this task was born from an @time note line.
    final int? sourceBlockId = task.sourceNoteBlockId;
    final Note? sourceNote = sourceBlockId == null
        ? null
        : ref.watch(sourceNoteForTaskProvider(sourceBlockId)).valueOrNull;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Check circle + title ────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: InkResponse(
                    radius: 22,
                    onTap: () {
                      ref.read(toggleTaskProvider.notifier).toggle(
                            task.id,
                            currentlyCompleted: done,
                          );
                      Navigator.of(context).pop();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 26,
                      height: 26,
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
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration:
                              done ? TextDecoration.lineThrough : null,
                          color: done
                              ? cs.onSurface.withAlpha(130)
                              : cs.onSurface,
                        ),
                  ),
                ),
                PriorityBadge(priority: task.priority),
              ],
            ),

            // ── Full note text ──────────────────────────────────────────────
            if ((task.note ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  task.note ?? '',
                  style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: cs.onSurface.withAlpha(180)),
                ),
              ),
            ],

            const SizedBox(height: 14),
            Divider(height: 1, thickness: 1, color: cs.outlineVariant),
            const SizedBox(height: 6),

            // ── Facts ───────────────────────────────────────────────────────
            if (task.dueDate != null)
              _fact(
                cs,
                Icons.event_rounded,
                _dueText(task),
              ),
            if (labels.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final Label l in labels)
                      Chip(
                        label: Text(l.name),
                        labelStyle: const TextStyle(fontSize: 12),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ),

            // ── Where it lives ──────────────────────────────────────────────
            _linkRow(
              context,
              cs,
              icon: Icons.list_alt_rounded,
              text: list?.name ?? 'Captured',
              onTap: list == null
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      context.push('/lists/${list.id}');
                    },
            ),
            if (sourceBlockId != null)
              _linkRow(
                context,
                cs,
                icon: Icons.sticky_note_2_outlined,
                text: sourceNote == null
                    ? 'From a note'
                    : 'From note: '
                        '${sourceNote.title.trim().isEmpty ? 'Untitled' : sourceNote.title}',
                onTap: sourceNote == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        context.push('/notes/${sourceNote.id}');
                      },
              ),

            const SizedBox(height: 12),

            // ── Actions ─────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/tasks/edit', extra: task);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// "Due Fri 2026-08-07 · 14:00 · 1h 30m" — only the parts that exist.
  static String _dueText(TaskModel task) {
    final List<String> parts = ['Due ${task.dueDate}'];
    final String? time = task.dueTime;
    if (time != null && time.isNotEmpty) parts.add(time);
    final int? mins = task.durationMinutes;
    if (mins != null && mins > 0) {
      final int h = mins ~/ 60, m = mins % 60;
      parts.add(h == 0 ? '${m}m' : (m == 0 ? '${h}h' : '${h}h ${m}m'));
    }
    return parts.join(' · ');
  }

  Widget _fact(ColorScheme cs, IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.onSurface.withAlpha(140)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 14, color: cs.onSurface.withAlpha(190))),
            ),
          ],
        ),
      );

  Widget _linkRow(BuildContext context, ColorScheme cs,
      {required IconData icon, required String text, VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.onSurface.withAlpha(140)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: onTap == null
                      ? cs.onSurface.withAlpha(190)
                      : cs.primary,
                  fontWeight:
                      onTap == null ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: cs.onSurface.withAlpha(120)),
          ],
        ),
      ),
    );
  }
}
