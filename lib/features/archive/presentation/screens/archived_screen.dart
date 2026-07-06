import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../archive_providers.dart';

/// Recovery bin for everything archived — tasks, lists, trackers, habits.
/// Each row restores (archivedAt → null) or deletes forever (with confirm).
class ArchivedScreen extends ConsumerWidget {
  const ArchivedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ArchiveService svc = ref.watch(archiveServiceProvider);
    final tasks = ref.watch(archivedTasksProvider).valueOrNull ?? const [];
    final lists = ref.watch(archivedListsProvider).valueOrNull ?? const [];
    final trackers =
        ref.watch(archivedTrackersProvider).valueOrNull ?? const [];
    final habits = ref.watch(archivedHabitsProvider).valueOrNull ?? const [];

    final bool anything = tasks.isNotEmpty ||
        lists.isNotEmpty ||
        trackers.isNotEmpty ||
        habits.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Archived')),
      body: !anything
          ? const Center(child: _EmptyAll())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _Section(
                  label: 'Tasks',
                  rows: [
                    for (final t in tasks)
                      _ArchivedRow(
                        title: t.title,
                        onRestore: () => svc.restoreTask(t.id),
                        onDelete: () => _confirmDelete(
                            context, t.title, () => svc.deleteTask(t.id)),
                      ),
                  ],
                ),
                _Section(
                  label: kListNounPlural,
                  rows: [
                    for (final l in lists)
                      _ArchivedRow(
                        title: l.name,
                        colorValue: l.colorValue,
                        onRestore: () => svc.restoreList(l.id),
                        onDelete: () => _confirmDelete(
                            context, l.name, () => svc.deleteList(l.id)),
                      ),
                  ],
                ),
                _Section(
                  label: 'Trackers',
                  rows: [
                    for (final tr in trackers)
                      _ArchivedRow(
                        title: tr.name,
                        onRestore: () => svc.restoreTracker(tr.id),
                        onDelete: () => _confirmDelete(context, tr.name,
                            () => svc.deleteTracker(tr.id)),
                      ),
                  ],
                ),
                _Section(
                  label: 'Habits',
                  rows: [
                    for (final h in habits)
                      _ArchivedRow(
                        title: h.name,
                        onRestore: () => svc.restoreHabit(h.id),
                        onDelete: () => _confirmDelete(
                            context, h.name, () => svc.deleteHabit(h.id)),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, String name, VoidCallback onConfirm) async {
    final bool? yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "$name" forever?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete forever')),
        ],
      ),
    );
    if (yes == true) onConfirm();
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.rows});
  final String label;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            '${label.toUpperCase()}  ·  ${rows.length}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
          ),
        ),
        ...rows,
      ],
    );
  }
}

class _ArchivedRow extends StatelessWidget {
  const _ArchivedRow({
    required this.title,
    required this.onRestore,
    required this.onDelete,
    this.colorValue,
  });

  final String title;
  final int? colorValue;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: colorValue != null
          ? Icon(Icons.circle, size: 14, color: Color(colorValue ?? 0))
          : const Icon(Icons.inventory_2_outlined),
      title: Text(title, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.unarchive_rounded),
            tooltip: 'Restore',
            onPressed: onRestore,
          ),
          IconButton(
            icon: Icon(Icons.delete_forever_rounded, color: cs.error),
            tooltip: 'Delete forever',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _EmptyAll extends StatelessWidget {
  const _EmptyAll();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inventory_2_outlined,
            size: 56, color: cs.onSurface.withAlpha(60)),
        const SizedBox(height: 12),
        Text('Nothing archived',
            style: TextStyle(color: cs.onSurface.withAlpha(140))),
      ],
    );
  }
}
