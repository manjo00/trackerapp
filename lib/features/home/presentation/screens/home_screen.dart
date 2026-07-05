import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/settings/settings_provider.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/providers/lists_providers.dart';
import '../../../tasks/presentation/providers/tasks_providers.dart';
import '../../../tasks/presentation/widgets/task_tile.dart';
import '../../data/home_block_type.dart';
import '../widgets/workout_block.dart';
import 'edit_home_screen.dart';

/// The app's landing dashboard.
///
/// Renders the user's blocks in their chosen order (settings.homeBlocks).
/// Long-press a block header to drag it into a new position; the ✎ button
/// opens the Edit Home screen for add/remove/reorder with full controls.
///
/// Task de-dupe follows the USER'S order: walking the blocks top-down, a
/// task appears only in the first block that claims it.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<HomeBlockType> layout =
        ref.watch(settingsProvider.select((s) => s.homeBlocks));

    // Task sources (watched up-front; cheap streams already running).
    final List<TaskModel> urgentAll = ref.watch(urgentTasksProvider);
    final List<TaskModel> dueTodayAll =
        ref.watch(tasksDueTodayProvider).valueOrNull ?? const [];
    final List<TaskModel> capturedAll =
        ref.watch(capturedTasksProvider).valueOrNull ?? const [];
    final List<TaskModel> week =
        ref.watch(thisWeekTasksProvider).valueOrNull ?? const [];

    // Build visible blocks in the user's order, de-duping as we go.
    final Set<int> shownIds = {};
    List<TaskModel> claim(List<TaskModel> tasks) {
      final List<TaskModel> mine =
          tasks.where((t) => !shownIds.contains(t.id)).toList();
      shownIds.addAll(mine.map((t) => t.id));
      return mine;
    }

    // Every enabled block always renders — an empty one shows a quiet
    // placeholder instead of vanishing (user feedback: the dashboard's
    // structure should stay put even on an empty day).
    final List<Widget> children = [];
    for (final HomeBlockType type in layout) {
      final Widget content = switch (type) {
        HomeBlockType.urgent =>
          _tasksOrEmpty(claim(urgentAll), 'Nothing urgent 🎉', cs),
        HomeBlockType.dueToday =>
          _tasksOrEmpty(claim(dueTodayAll), 'Nothing due today', cs),
        HomeBlockType.captured =>
          _tasksOrEmpty(claim(capturedAll), 'Nothing captured', cs),
        HomeBlockType.thisWeek => _WeekCard(tasks: week),
        HomeBlockType.workout => const WorkoutBlock(),
      };

      children.add(Column(
        key: ValueKey(type),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Long-press the header to drag the whole block.
          ReorderableDelayedDragStartListener(
            index: children.length,
            child: _BlockHeader(type: type, color: _headerColor(type, cs)),
          ),
          content,
        ],
      ));
    }

    return Scaffold(
      body: ReorderableListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        buildDefaultDragHandles: false,
        // onReorderItem (Flutter 3.41+) already adjusts newIndex for the
        // removed item — no manual `newIndex -= 1` dance. Children map 1:1
        // onto the layout (every enabled block renders), so this is a
        // straight list move.
        onReorderItem: (int oldIndex, int newIndex) {
          if (oldIndex == newIndex) return;
          final List<HomeBlockType> next = List.of(layout);
          final HomeBlockType moved = next.removeAt(oldIndex);
          next.insert(newIndex, moved);
          ref.read(settingsProvider.notifier).setHomeBlocks(next);
        },
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(Icons.edit_rounded,
                    size: 18, color: cs.onSurface.withAlpha(120)),
                tooltip: 'Edit Home',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const EditHomeScreen()),
                ),
              ),
            ),
            if (layout.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48, bottom: 24),
                child: Column(
                  children: [
                    const Text('🏗️', style: TextStyle(fontSize: 44)),
                    const SizedBox(height: 10),
                    Text('Home is empty',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Add blocks with the ✎ above',
                      style: TextStyle(
                          fontSize: 13, color: cs.onSurface.withAlpha(120)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        children: children,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () => context.push('/tasks/add'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  static Color _headerColor(HomeBlockType type, ColorScheme cs) =>
      switch (type) {
        HomeBlockType.urgent => cs.error,
        HomeBlockType.dueToday => cs.primary,
        HomeBlockType.captured => cs.tertiary,
        HomeBlockType.thisWeek => cs.secondary,
        HomeBlockType.workout => cs.primary,
      };

  /// Task tiles, or a quiet placeholder card when the block is empty.
  static Widget _tasksOrEmpty(
      List<TaskModel> tasks, String emptyText, ColorScheme cs) {
    if (tasks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            emptyText,
            style: TextStyle(
                fontSize: 13, color: cs.onSurface.withAlpha(110)),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final t in tasks) TaskTile(task: t, showListName: true),
      ],
    );
  }
}

// ── Block header (also the drag handle) ───────────────────────────────────

class _BlockHeader extends StatelessWidget {
  const _BlockHeader({required this.type, required this.color});

  final HomeBlockType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Row(
        children: [
          Icon(type.icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            type.label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
          ),
        ],
      ),
    );
  }
}

// ── This-week card ────────────────────────────────────────────────────────

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.tasks});

  final List<TaskModel> tasks;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final DateTime today = DateTime.now();

    final Map<String, List<TaskModel>> byDate = {};
    for (final TaskModel t in tasks) {
      final String? d = t.dueDate;
      if (d != null) (byDate[d] ??= []).add(t);
    }

    const List<String> weekdays = [
      '', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];

    return Card(
      child: Column(
        children: [
          for (int i = 0; i < 7; i++)
            _dayRow(
              context,
              cs,
              DateTime(today.year, today.month, today.day + i),
              byDate,
              weekdays,
              isToday: i == 0,
            ),
        ],
      ),
    );
  }

  Widget _dayRow(BuildContext context, ColorScheme cs, DateTime day,
      Map<String, List<TaskModel>> byDate, List<String> weekdays,
      {required bool isToday}) {
    final String key = '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final List<TaskModel> dayTasks = byDate[key] ?? const [];
    if (dayTasks.isEmpty && !isToday) return const SizedBox.shrink();

    final String preview = dayTasks.take(2).map((t) => t.title).join(' · ');

    return InkWell(
      onTap: () => context.go('/planner'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                isToday ? 'Today' : weekdays[day.weekday],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday ? cs.primary : cs.onSurface.withAlpha(160),
                ),
              ),
            ),
            Expanded(
              child: Text(
                preview.isEmpty ? '—' : preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: preview.isEmpty
                      ? cs.onSurface.withAlpha(80)
                      : cs.onSurface.withAlpha(180),
                ),
              ),
            ),
            if (dayTasks.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                '${dayTasks.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withAlpha(120),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
