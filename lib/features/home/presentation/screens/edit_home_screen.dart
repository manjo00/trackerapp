import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/settings_provider.dart';
import '../../data/home_block_type.dart';

/// Full controls for the Home dashboard layout: drag to reorder, remove,
/// and re-add blocks. Every change applies instantly (no save button).
class EditHomeScreen extends ConsumerWidget {
  const EditHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<HomeBlockType> enabled =
        ref.watch(settingsProvider.select((s) => s.homeBlocks));
    final List<HomeBlockType> available =
        HomeBlockType.values.where((t) => !enabled.contains(t)).toList();
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Home')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'BLOCKS — drag to reorder',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
            ),
          ),
          if (enabled.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No blocks on Home — add some below',
                style: TextStyle(color: cs.onSurface.withAlpha(140)),
              ),
            ),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // newIndex arrives pre-adjusted (onReorderItem, Flutter 3.41+).
            onReorderItem: (int oldIndex, int newIndex) {
              final List<HomeBlockType> next = List.of(enabled);
              final HomeBlockType moved = next.removeAt(oldIndex);
              next.insert(newIndex, moved);
              notifier.setHomeBlocks(next);
            },
            children: [
              for (final HomeBlockType type in enabled)
                ListTile(
                  key: ValueKey(type),
                  leading: Icon(type.icon, color: cs.primary),
                  title: Text(type.label),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline_rounded,
                            color: cs.error),
                        tooltip: 'Remove from Home',
                        onPressed: () => notifier.setHomeBlocks(
                            enabled.where((t) => t != type).toList()),
                      ),
                      const Icon(Icons.drag_handle_rounded),
                    ],
                  ),
                ),
            ],
          ),
          if (available.isNotEmpty) ...[
            const Divider(indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'ADD BLOCK',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
              ),
            ),
            for (final HomeBlockType type in available)
              ListTile(
                leading: Icon(type.icon, color: cs.onSurface.withAlpha(140)),
                title: Text(type.label),
                trailing: Icon(Icons.add_circle_outline_rounded,
                    color: cs.primary),
                onTap: () => notifier.setHomeBlocks([...enabled, type]),
              ),
          ],
        ],
      ),
    );
  }
}
