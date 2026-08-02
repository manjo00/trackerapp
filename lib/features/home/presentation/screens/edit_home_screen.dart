import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/home_block_config.dart';
import '../../data/home_block_type.dart';
import '../providers/home_blocks_providers.dart';
import '../widgets/note_picker_sheet.dart';

/// Full controls for the Home dashboard layout (home_blocks rows): drag to
/// reorder, remove, and add blocks. Every change applies instantly (no save
/// button). "Pinned note" can be added any number of times — one per note —
/// and tapping a pinned row re-points it at a different note.
class EditHomeScreen extends ConsumerWidget {
  const EditHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<HomeBlock> rows =
        ref.watch(homeBlockRowsProvider).valueOrNull ?? const [];
    final dao = ref.read(homeBlocksDaoProvider);

    HomeBlockType? typeOf(HomeBlock row) =>
        HomeBlockType.values.where((t) => t.name == row.type).firstOrNull;

    // Single-instance types not currently on the dashboard; a pinned note can
    // always be added again (for another note).
    final Set<String> present = {for (final r in rows) r.type};
    final List<HomeBlockType> available = [
      for (final HomeBlockType t in HomeBlockType.values)
        if (t == HomeBlockType.pinnedNote || !present.contains(t.name)) t
    ];

    Future<void> addBlock(HomeBlockType type) async {
      if (type == HomeBlockType.pinnedNote) {
        final Note? picked = await showNotePicker(context, ref);
        if (picked == null) return;
        await dao.addBlock(type, configJson: pinnedNoteConfig(picked.id));
      } else {
        await dao.addBlock(type);
      }
    }

    Future<void> changeNote(HomeBlock row) async {
      final Note? picked = await showNotePicker(context, ref);
      if (picked == null) return;
      await dao.updateConfig(row.id, pinnedNoteConfig(picked.id));
    }

    Widget? pinnedSubtitle(HomeBlock row) {
      final int? noteId = pinnedNoteIdFromConfig(row.configJson);
      final Note? note = noteId == null
          ? null
          : ref.watch(watchNoteProvider(noteId)).valueOrNull;
      final String title = note == null
          ? 'No note chosen — tap to pick'
          : (note.title.trim().isEmpty ? 'Untitled' : note.title);
      return Text(title, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

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
          if (rows.isEmpty)
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
              final List<int> ids = rows.map((r) => r.id).toList();
              final int moved = ids.removeAt(oldIndex);
              ids.insert(newIndex, moved);
              dao.reorderBlocks(ids);
            },
            children: [
              for (final HomeBlock row in rows)
                if (typeOf(row) case final HomeBlockType type)
                  ListTile(
                    key: ValueKey(row.id),
                    leading: Icon(type.icon, color: cs.primary),
                    title: Text(type.label),
                    subtitle: type == HomeBlockType.pinnedNote
                        ? pinnedSubtitle(row)
                        : null,
                    onTap: type == HomeBlockType.pinnedNote
                        ? () => changeNote(row)
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline_rounded,
                              color: cs.error),
                          tooltip: 'Remove from Home',
                          onPressed: () => dao.deleteBlock(row.id),
                        ),
                        const Icon(Icons.drag_handle_rounded),
                      ],
                    ),
                  ),
            ],
          ),
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
              subtitle: type == HomeBlockType.pinnedNote
                  ? const Text('Show a note\'s content on Home')
                  : null,
              trailing:
                  Icon(Icons.add_circle_outline_rounded, color: cs.primary),
              onTap: () => addBlock(type),
            ),
        ],
      ),
    );
  }
}
