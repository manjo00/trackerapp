import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../tasks/presentation/providers/lists_providers.dart';
import '../../data/home_block_config.dart';
import '../../data/home_block_type.dart';
import '../providers/home_blocks_providers.dart';
import '../widgets/block_config_sheet.dart';
import '../widgets/note_picker_sheet.dart';

/// Full controls for the Home dashboard layout (home_blocks rows): drag to
/// reorder, remove, add blocks, and open each block's ⚙ options. Every change
/// applies instantly (no save button). Pinned note / list / label blocks can
/// be added any number of times — one per target — and tapping such a row
/// re-points it.
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

    // Multi-instance types are always offered; single-instance ones only
    // while absent from the dashboard.
    final Set<String> present = {for (final r in rows) r.type};
    final List<HomeBlockType> available = [
      for (final HomeBlockType t in HomeBlockType.values)
        if (HomeBlockType.multiInstance.contains(t) || !present.contains(t.name))
          t
    ];

    Future<TaskList?> pickList() async {
      final List<TaskList> lists =
          ref.read(taskListsProvider).valueOrNull ?? const [];
      return showModalBottomSheet<TaskList>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: lists.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No lists yet — create one in Lists first.'))
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final TaskList l in lists)
                      ListTile(
                        leading: Icon(Icons.list_alt_rounded,
                            color: Color(l.colorValue)),
                        title: Text(l.name),
                        onTap: () => Navigator.of(ctx).pop(l),
                      ),
                  ],
                ),
        ),
      );
    }

    Future<Label?> pickLabel() async {
      final List<Label> labels =
          ref.read(labelsProvider).valueOrNull ?? const [];
      return showModalBottomSheet<Label>(
        context: context,
        showDragHandle: true,
        builder: (ctx) => SafeArea(
          child: labels.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No labels yet — create one in a task first.'))
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final Label l in labels)
                      ListTile(
                        leading: const Icon(Icons.label_rounded),
                        title: Text(l.name),
                        onTap: () => Navigator.of(ctx).pop(l),
                      ),
                  ],
                ),
        ),
      );
    }

    Future<void> addBlock(HomeBlockType type) async {
      switch (type) {
        case HomeBlockType.pinnedNote:
          final Note? picked = await showNotePicker(context, ref);
          if (picked == null) return;
          await dao.addBlock(type, configJson: pinnedNoteConfig(picked.id));
        case HomeBlockType.list:
          final TaskList? picked = await pickList();
          if (picked == null) return;
          await dao.addBlock(type, configJson: listConfig(picked.id));
        case HomeBlockType.label:
          final Label? picked = await pickLabel();
          if (picked == null) return;
          await dao.addBlock(type, configJson: labelConfig(picked.id));
        default:
          await dao.addBlock(type);
      }
    }

    /// Re-point a multi-instance block at a different note/list/label.
    Future<void> changeTarget(HomeBlock row, HomeBlockType type) async {
      switch (type) {
        case HomeBlockType.pinnedNote:
          final Note? picked = await showNotePicker(context, ref);
          if (picked == null) return;
          await dao.updateConfig(row.id,
              mergeConfig(row.configJson, {'noteId': picked.id}));
        case HomeBlockType.list:
          final TaskList? picked = await pickList();
          if (picked == null) return;
          await dao.updateConfig(
              row.id, mergeConfig(row.configJson, {'listId': picked.id}));
        case HomeBlockType.label:
          final Label? picked = await pickLabel();
          if (picked == null) return;
          await dao.updateConfig(
              row.id, mergeConfig(row.configJson, {'labelId': picked.id}));
        default:
          break;
      }
    }

    /// What this block points at (pinned note / list / label rows only).
    Widget? subtitleFor(HomeBlock row, HomeBlockType type) {
      String? text;
      switch (type) {
        case HomeBlockType.pinnedNote:
          final int? id = pinnedNoteIdFromConfig(row.configJson);
          final Note? note =
              id == null ? null : ref.watch(watchNoteProvider(id)).valueOrNull;
          text = note == null
              ? 'No note chosen — tap to pick'
              : (note.title.trim().isEmpty ? 'Untitled' : note.title);
        case HomeBlockType.list:
          final int? id = listIdFromConfig(row.configJson);
          final List<TaskList> lists =
              ref.watch(taskListsProvider).valueOrNull ?? const [];
          text = lists.where((l) => l.id == id).firstOrNull?.name ??
              'No list chosen — tap to pick';
        case HomeBlockType.label:
          final int? id = labelIdFromConfig(row.configJson);
          final List<Label> labels =
              ref.watch(labelsProvider).valueOrNull ?? const [];
          text = labels.where((l) => l.id == id).firstOrNull?.name ??
              'No label chosen — tap to pick';
        default:
          return null;
      }
      return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
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
                    title: Text(type.title),
                    subtitle: subtitleFor(row, type),
                    onTap: HomeBlockType.multiInstance.contains(type)
                        ? () => changeTarget(row, type)
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (blockHasOptions(type))
                          IconButton(
                            icon: Icon(Icons.tune_rounded,
                                size: 20, color: cs.onSurface.withAlpha(150)),
                            tooltip: 'Block options',
                            onPressed: () =>
                                showBlockConfigSheet(context, row, type),
                          ),
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
              title: Text(type.title),
              subtitle: switch (type) {
                HomeBlockType.pinnedNote =>
                  const Text('Work in a note right on Home'),
                HomeBlockType.list => const Text('Pin one list\'s tasks'),
                HomeBlockType.label =>
                  const Text('Tasks carrying one label'),
                HomeBlockType.habits => const Text('Today\'s check-offs'),
                HomeBlockType.shift =>
                  const Text('Today + next shift at a glance'),
                HomeBlockType.done =>
                  const Text('What you\'ve completed — un-tick mistakes'),
                _ => null,
              },
              trailing:
                  Icon(Icons.add_circle_outline_rounded, color: cs.primary),
              onTap: () => addBlock(type),
            ),
        ],
      ),
    );
  }
}
