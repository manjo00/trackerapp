import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/home_block_config.dart';
import '../../data/home_block_type.dart';
import '../providers/home_blocks_providers.dart';

/// Block types whose task list can be capped ("Items shown").
const Set<HomeBlockType> kLimitableTypes = {
  HomeBlockType.urgent,
  HomeBlockType.dueToday,
  HomeBlockType.captured,
  HomeBlockType.list,
  HomeBlockType.label,
  HomeBlockType.done,
};

/// Block types that may auto-hide while they have nothing to show.
const Set<HomeBlockType> kHideableTypes = {
  HomeBlockType.urgent,
  HomeBlockType.dueToday,
  HomeBlockType.captured,
  HomeBlockType.list,
  HomeBlockType.label,
  HomeBlockType.shift,
  HomeBlockType.done,
};

/// Whether Edit Home should offer a ⚙ options sheet for [type].
bool blockHasOptions(HomeBlockType type) =>
    kLimitableTypes.contains(type) ||
    kHideableTypes.contains(type) ||
    type == HomeBlockType.thisWeek;

/// Per-block options: only the controls that apply to this block's type.
/// Every change writes to home_blocks.configJson immediately (no save button).
Future<void> showBlockConfigSheet(
        BuildContext context, HomeBlock row, HomeBlockType type) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _BlockConfigSheet(blockId: row.id, type: type),
    );

class _BlockConfigSheet extends ConsumerWidget {
  const _BlockConfigSheet({required this.blockId, required this.type});

  final int blockId;
  final HomeBlockType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    // Watch the live row so the sheet reflects each change instantly.
    final HomeBlock? row = (ref.watch(homeBlockRowsProvider).valueOrNull ??
            const <HomeBlock>[])
        .where((r) => r.id == blockId)
        .firstOrNull;
    if (row == null) return const SizedBox.shrink();
    final dao = ref.read(homeBlocksDaoProvider);

    void write(Map<String, Object?> updates) =>
        dao.updateConfig(row.id, mergeConfig(row.configJson, updates));

    Widget chips<T>({
      required String title,
      required List<(String, T?)> options,
      required T? current,
      required String key,
    }) =>
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withAlpha(170))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final (String label, T? value) in options)
                    ChoiceChip(
                      label: Text(label),
                      selected: current == value,
                      onSelected: (_) => write({key: value}),
                    ),
                ],
              ),
            ],
          ),
        );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(type.icon, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('${type.title} options',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (kLimitableTypes.contains(type))
            chips<int>(
              title: 'Items shown',
              options: const [('All', null), ('3', 3), ('5', 5), ('10', 10)],
              current: limitFromConfig(row.configJson),
              key: 'limit',
            ),
          if (type == HomeBlockType.thisWeek)
            chips<int>(
              title: 'Days ahead',
              options: const [('3', 3), ('5', 5), ('7', null)],
              current: daysFromConfig(row.configJson),
              key: 'days',
            ),
          if (kHideableTypes.contains(type))
            SwitchListTile(
              title: const Text('Hide when empty'),
              subtitle: const Text('The block disappears while it has '
                  'nothing to show'),
              value: hideWhenEmptyFromConfig(row.configJson),
              onChanged: (v) => write({'hideWhenEmpty': v ? true : null}),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
