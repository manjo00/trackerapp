import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/app_database.dart';
import '../../../coach/data/coach_tip.dart';
import '../../../coach/presentation/coach_controller.dart';
import '../../../coach/presentation/coach_target.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/providers/lists_providers.dart';
import '../../../tasks/presentation/providers/tasks_providers.dart';
import '../../../tasks/presentation/widgets/task_tile.dart';
import '../../data/home_block_config.dart';
import '../../data/home_block_type.dart';
import '../../data/home_layout.dart';
import '../providers/home_blocks_providers.dart';
import '../widgets/habits_block.dart';
import '../widgets/notes_block.dart';
import '../widgets/pinned_note_block.dart';
import '../widgets/shift_block.dart';
import '../widgets/workout_block.dart';
import 'edit_home_screen.dart';

/// The app's landing dashboard.
///
/// Renders the user's blocks in their chosen order (home_blocks rows, v21).
/// Long-press a block header to drag it into a new position (phone layout);
/// the ✎ button opens Edit Home for add/remove/reorder + per-block options.
/// On wide screens (tablet / unfolded foldable) blocks flow into 2–3 columns,
/// distributed round-robin so the top rows keep the user's priorities; drag
/// reorder there lives in Edit Home.
///
/// Task de-dupe follows the USER'S order: walking the blocks top-down, a task
/// appears only in the first block that SHOWS it — a task hidden by one
/// block's "items shown" cap is still available to a later block.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    // Rows whose type this build understands (unknown names from a newer
    // build are skipped, never crashed on).
    final List<(HomeBlock, HomeBlockType)> layout = [
      for (final HomeBlock row
          in ref.watch(homeBlockRowsProvider).valueOrNull ??
              const <HomeBlock>[])
        for (final HomeBlockType type in HomeBlockType.values)
          if (type.name == row.type) (row, type),
    ];

    // Task sources (watched up-front; cheap streams already running).
    final List<TaskModel> urgentAll = ref.watch(urgentTasksProvider);
    final List<TaskModel> dueTodayAll =
        ref.watch(tasksDueTodayProvider).valueOrNull ?? const [];
    final List<TaskModel> capturedAll =
        ref.watch(capturedTasksProvider).valueOrNull ?? const [];
    final List<TaskModel> week =
        ref.watch(thisWeekTasksProvider).valueOrNull ?? const [];
    final List<TaskModel> allTasks =
        ref.watch(allTasksProvider).valueOrNull ?? const [];
    final List<TaskList> allLists =
        ref.watch(taskListsProvider).valueOrNull ?? const [];
    final List<Label> allLabels =
        ref.watch(labelsProvider).valueOrNull ?? const [];

    // De-dupe in the user's order, claiming only what a block SHOWS.
    final Set<int> shownIds = {};
    (List<TaskModel>, int) claim(List<TaskModel> tasks, int? limit) {
      final List<TaskModel> mine = tasks
          .where((t) => !shownIds.contains(t.id))
          .toList();
      final List<TaskModel> shown = limit == null
          ? mine
          : mine.take(limit).toList();
      shownIds.addAll(shown.map((t) => t.id));
      return (shown, mine.length - shown.length);
    }

    final List<Widget> children = [];
    for (final (HomeBlock row, HomeBlockType type) in layout) {
      final int? limit = limitFromConfig(row.configJson);
      final bool hideWhenEmpty = hideWhenEmptyFromConfig(row.configJson);
      final bool collapsed = collapsedFromConfig(row.configJson);

      String? titleOverride;
      Widget content;
      bool isEmpty = false;

      switch (type) {
        case HomeBlockType.urgent:
          final (shown, more) = claim(urgentAll, limit);
          isEmpty = shown.isEmpty && more == 0;
          content = _tasksOrEmpty(shown, more, 'Nothing urgent 🎉', cs);
        case HomeBlockType.dueToday:
          final (shown, more) = claim(dueTodayAll, limit);
          isEmpty = shown.isEmpty && more == 0;
          content = _tasksOrEmpty(shown, more, 'Nothing due today', cs);
        case HomeBlockType.captured:
          final (shown, more) = claim(capturedAll, limit);
          isEmpty = shown.isEmpty && more == 0;
          content = _tasksOrEmpty(shown, more, 'Nothing captured', cs);
        case HomeBlockType.thisWeek:
          content = _WeekCard(
            tasks: week,
            days: daysFromConfig(row.configJson) ?? 7,
          );
        case HomeBlockType.workout:
          content = const WorkoutBlock();
        case HomeBlockType.notes:
          content = const NotesBlock();
        case HomeBlockType.pinnedNote:
          content = PinnedNoteBlock(row: row);
          final int? noteId = pinnedNoteIdFromConfig(row.configJson);
          final Note? note = noteId == null
              ? null
              : ref.watch(watchNoteProvider(noteId)).valueOrNull;
          final String t = note?.title.trim() ?? '';
          if (t.isNotEmpty) titleOverride = t;
        case HomeBlockType.list:
          final int? listId = listIdFromConfig(row.configJson);
          final TaskList? list = allLists
              .where((l) => l.id == listId)
              .firstOrNull;
          titleOverride = list?.name;
          final List<TaskModel> source = listId == null
              ? const []
              : (ref.watch(tasksForListProvider(listId)).valueOrNull ??
                        const [])
                    .where((t) => !t.isCompleted)
                    .toList();
          final (shown, more) = claim(source, limit);
          isEmpty = shown.isEmpty && more == 0;
          content = _tasksOrEmpty(
            shown,
            more,
            'Nothing here',
            cs,
            onMore: listId == null
                ? null
                : () => context.push('/lists/$listId'),
          );
        case HomeBlockType.label:
          final int? labelId = labelIdFromConfig(row.configJson);
          final Label? lbl = allLabels
              .where((l) => l.id == labelId)
              .firstOrNull;
          titleOverride = lbl?.name;
          final Set<int> ids = labelId == null
              ? const {}
              : ref.watch(taskIdsForLabelProvider(labelId)).valueOrNull ??
                    const {};
          final List<TaskModel> source = allTasks
              .where((t) => ids.contains(t.id) && !t.isCompleted)
              .toList();
          final (shown, more) = claim(source, limit);
          isEmpty = shown.isEmpty && more == 0;
          content = _tasksOrEmpty(shown, more, 'Nothing here', cs);
        case HomeBlockType.habits:
          content = const HabitsBlock();
        case HomeBlockType.shift:
          final byDate =
              ref.watch(shiftGlanceEmptyProvider).valueOrNull ?? false;
          isEmpty = byDate;
          content = const ShiftBlock();
        case HomeBlockType.done:
          // Completed-but-not-archived tasks, freshest due date first (there
          // is no completedAt column to sort by).
          final List<TaskModel> source =
              allTasks.where((t) => t.isCompleted).toList()..sort((a, b) {
                final int d = (b.dueDate ?? '').compareTo(a.dueDate ?? '');
                return d != 0 ? d : b.createdAt.compareTo(a.createdAt);
              });
          final (shown, more) = claim(source, limit);
          isEmpty = shown.isEmpty && more == 0;
          content = _tasksOrEmpty(shown, more, 'Nothing completed yet', cs);
      }

      // "Hide when empty" removes the whole block, header included.
      if (hideWhenEmpty && isEmpty) continue;

      children.add(
        Column(
          key: ValueKey(row.id),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Long-press the header to drag the whole block (phone layout; a
            // no-op inside the wide multi-column layout). The first header is a
            // coach-mark target.
            ReorderableDelayedDragStartListener(
              index: children.length,
              child: _coachWrap(
                children.isEmpty,
                'home.firstHeader',
                child: _BlockHeader(
                  type: type,
                  color: _headerColor(type, cs),
                  titleOverride: titleOverride,
                  collapsed: collapsed,
                  onToggleCollapse: () => ref
                      .read(homeBlocksDaoProvider)
                      .updateConfig(
                        row.id,
                        mergeConfig(row.configJson, {'collapsed': !collapsed}),
                      ),
                ),
              ),
            ),
            if (!collapsed) content,
          ],
        ),
      );
    }

    final Widget headerBar = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: CoachTarget(
            id: 'home.edit',
            child: IconButton(
              icon: Icon(
                Icons.edit_rounded,
                size: 18,
                color: cs.onSurface.withAlpha(120),
              ),
              tooltip: 'Edit Home',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const EditHomeScreen()),
              ),
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
                Text(
                  'Home is empty',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Add blocks with the ✎ above',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
      ],
    );

    return CoachMarks(
      screen: kCoachHome,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final int cols = constraints.maxWidth >= 1080
                ? 3
                : (constraints.maxWidth >= 720 ? 2 : 1);
            if (cols == 1) {
              return ReorderableListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                buildDefaultDragHandles: false,
                // onReorderItem (Flutter 3.41+) already adjusts newIndex for the
                // removed item. Children map 1:1 onto the RENDERED blocks;
                // hidden-when-empty rows keep their stored order untouched.
                onReorderItem: (int oldIndex, int newIndex) {
                  if (oldIndex == newIndex) return;
                  final List<int> rendered = [
                    for (final Widget w in children)
                      ((w.key as ValueKey<int>?)?.value ?? -1),
                  ];
                  final int moved = rendered.removeAt(oldIndex);
                  rendered.insert(newIndex, moved);
                  // Splice the moved visible ids back over the full stored order.
                  final List<int> all = [for (final (r, _) in layout) r.id];
                  final Set<int> visible = rendered.toSet();
                  int vi = 0;
                  final List<int> next = [
                    for (final int id in all)
                      visible.contains(id) ? rendered[vi++] : id,
                  ];
                  ref.read(homeBlocksDaoProvider).reorderBlocks(next);
                },
                header: headerBar,
                children: children,
              );
            }
            // Wide layout: user order distributed round-robin across columns.
            final List<List<Widget>> columns = distributeRoundRobin(
              children,
              cols,
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  headerBar,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int c = 0; c < columns.length; c++) ...[
                        if (c > 0) const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: columns[c],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: CoachTarget(
          id: 'home.fab',
          child: FloatingActionButton(
            heroTag: 'home_fab',
            onPressed: () => context.push('/tasks/add'),
            child: const Icon(Icons.add_rounded),
          ),
        ),
      ),
    );
  }

  /// Marks [child] as a coach-mark target only [when] it is the right one
  /// (e.g. the FIRST block header stands in for "any block header").
  static Widget _coachWrap(bool when, String id, {required Widget child}) =>
      when ? CoachTarget(id: id, child: child) : child;

  static Color _headerColor(HomeBlockType type, ColorScheme cs) =>
      switch (type) {
        HomeBlockType.urgent => cs.error,
        HomeBlockType.dueToday => cs.primary,
        HomeBlockType.captured => cs.tertiary,
        HomeBlockType.thisWeek => cs.secondary,
        HomeBlockType.workout => cs.primary,
        HomeBlockType.notes => cs.tertiary,
        HomeBlockType.pinnedNote => cs.secondary,
        HomeBlockType.list => cs.primary,
        HomeBlockType.label => cs.tertiary,
        HomeBlockType.habits => cs.secondary,
        HomeBlockType.shift => cs.primary,
        HomeBlockType.done => cs.secondary,
      };

  /// Task tiles (+ a muted "+N more"), or a quiet placeholder when empty.
  static Widget _tasksOrEmpty(
    List<TaskModel> tasks,
    int more,
    String emptyText,
    ColorScheme cs, {
    VoidCallback? onMore,
  }) {
    if (tasks.isEmpty && more == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            emptyText,
            style: TextStyle(fontSize: 13, color: cs.onSurface.withAlpha(110)),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in tasks) TaskTile(task: t, showListName: true),
        if (more > 0)
          InkWell(
            onTap: onMore,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Text(
                '+$more more',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: onMore == null
                      ? cs.onSurface.withAlpha(120)
                      : cs.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Block header (also the drag handle) ───────────────────────────────────

class _BlockHeader extends StatelessWidget {
  const _BlockHeader({
    required this.type,
    required this.color,
    this.titleOverride,
    this.collapsed = false,
    this.onToggleCollapse,
  });

  final HomeBlockType type;
  final Color color;

  /// Custom header text (a pinned note / list / label shows its own name).
  final String? titleOverride;

  /// Folded on Home — content hidden, chevron points right.
  final bool collapsed;
  final VoidCallback? onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Row(
        children: [
          Icon(type.icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              (titleOverride ?? type.title).toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          if (onToggleCollapse != null)
            InkResponse(
              onTap: onToggleCollapse,
              radius: 18,
              child: Icon(
                collapsed
                    ? Icons.chevron_right_rounded
                    : Icons.expand_more_rounded,
                size: 20,
                color: cs.onSurface.withAlpha(120),
              ),
            ),
        ],
      ),
    );
  }
}

// ── This-week card ────────────────────────────────────────────────────────

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.tasks, this.days = 7});

  final List<TaskModel> tasks;

  /// How many days ahead to show (per-block "Days ahead" option, max 7 — the
  /// source stream covers a week).
  final int days;

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
      '',
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return Card(
      child: Column(
        children: [
          for (int i = 0; i < days.clamp(1, 7); i++)
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

  Widget _dayRow(
    BuildContext context,
    ColorScheme cs,
    DateTime day,
    Map<String, List<TaskModel>> byDate,
    List<String> weekdays, {
    required bool isToday,
  }) {
    final String key =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-'
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
