import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../habits/data/models/habit_with_status.dart';
import '../../../habits/presentation/providers/habits_providers.dart';
import '../../../shifts/presentation/providers/shifts_providers.dart';
import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/providers/lists_providers.dart';
import '../../../tasks/presentation/widgets/task_tile.dart';
import '../day_grid_layout.dart';
import '../providers/planner_providers.dart';
import 'day_time_grid.dart';

/// Day panel of the Planner: habits + tasks for [selectedDate], in either
/// a list (timed-by-start, then untimed-by-urgency) or a 24-hour time grid.
///
/// Header controls: List ⇄ Grid switch and a ⋮ menu with per-visit filters
/// (hide completed, by list, by label) plus the persisted default view.
class DayDetailView extends ConsumerStatefulWidget {
  const DayDetailView({required this.selectedDate, super.key});

  final DateTime selectedDate;

  @override
  ConsumerState<DayDetailView> createState() => _DayDetailViewState();
}

class _DayDetailViewState extends ConsumerState<DayDetailView> {
  late bool _grid;
  bool _hideCompleted = false;

  /// null = all lists · -1 = Captured only · otherwise a list id.
  int? _filterListId;
  int? _filterLabelId; // null = all labels

  @override
  void initState() {
    super.initState();
    _grid = ref.read(settingsProvider).plannerDayView == 'grid';
  }

  String get _dateStr =>
      '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<List<TaskModel>> tasksAsync =
        ref.watch(tasksForDateProvider(_dateStr));

    // Label filter needs the label's task-id set (empty while loading —
    // brief flicker beats blocking the whole panel).
    final Set<int>? labelTaskIds = _filterLabelId == null
        ? null
        : ref.watch(taskIdsForLabelProvider(_filterLabelId ?? -1)).valueOrNull ??
            const {};

    List<TaskModel> applyFilters(List<TaskModel> tasks) => tasks.where((t) {
          if (_hideCompleted && t.isCompleted) return false;
          if (_filterListId == -1 && t.listId != null) return false;
          if (_filterListId != null &&
              _filterListId != -1 &&
              t.listId != _filterListId) {
            return false;
          }
          if (labelTaskIds != null && !labelTaskIds.contains(t.id)) {
            return false;
          }
          return true;
        }).toList();

    final bool filtersActive =
        _hideCompleted || _filterListId != null || _filterLabelId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header: view switch + menu ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 4, 0),
          child: Row(
            children: [
              if (filtersActive)
                Expanded(
                  child: Text(
                    'Filters on',
                    style: TextStyle(
                        fontSize: 11, color: cs.primary.withAlpha(180)),
                  ),
                )
              else
                const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  _grid
                      ? Icons.view_agenda_outlined
                      : Icons.grid_view_rounded,
                  size: 18,
                  color: cs.onSurface.withAlpha(150),
                ),
                tooltip: _grid ? 'List view' : 'Time grid',
                onPressed: () => setState(() => _grid = !_grid),
              ),
              PopupMenuButton<String>(
                iconSize: 18,
                onSelected: _onMenu,
                itemBuilder: (context) => [
                  CheckedPopupMenuItem(
                    value: 'hide_completed',
                    checked: _hideCompleted,
                    child: const Text('Hide completed'),
                  ),
                  const PopupMenuItem(
                      value: 'filter_list', child: Text('Filter by list…')),
                  const PopupMenuItem(
                      value: 'filter_label',
                      child: Text('Filter by label…')),
                  if (filtersActive)
                    const PopupMenuItem(
                        value: 'clear', child: Text('Clear filters')),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'default_view',
                    child: Text(
                        'Default view: ${ref.read(settingsProvider).plannerDayView == 'grid' ? 'Grid' : 'List'} → '
                        '${ref.read(settingsProvider).plannerDayView == 'grid' ? 'List' : 'Grid'}'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Body ───────────────────────────────────────────────────────
        Expanded(
          child: tasksAsync.when(
            skipLoadingOnReload: true,
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (_, __) =>
                const Center(child: Text('Could not load tasks')),
            data: (List<TaskModel> all) {
              final List<TaskModel> tasks = applyFilters(all);
              return _grid
                  ? _buildGrid(tasks)
                  : _buildList(context, tasks);
            },
          ),
        ),
      ],
    );
  }

  void _onMenu(String action) {
    switch (action) {
      case 'hide_completed':
        setState(() => _hideCompleted = !_hideCompleted);
      case 'filter_list':
        _pickListFilter();
      case 'filter_label':
        _pickLabelFilter();
      case 'clear':
        setState(() {
          _hideCompleted = false;
          _filterListId = null;
          _filterLabelId = null;
        });
      case 'default_view':
        final String next =
            ref.read(settingsProvider).plannerDayView == 'grid'
                ? 'list'
                : 'grid';
        ref.read(settingsProvider.notifier).setPlannerDayView(next);
        setState(() => _grid = next == 'grid');
    }
  }

  Future<void> _pickListFilter() async {
    final List<TaskList> lists =
        ref.read(taskListsProvider).valueOrNull ?? const [];
    final int? picked = await showDialog<int?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Show tasks from'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('All'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, -1),
            child: const Text('Captured (no list)'),
          ),
          for (final TaskList l in lists)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, l.id),
              child: Row(children: [
                Icon(Icons.circle, size: 12, color: Color(l.colorValue)),
                const SizedBox(width: 10),
                Text(l.name),
              ]),
            ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _filterListId = picked);
  }

  Future<void> _pickLabelFilter() async {
    final List<Label> labels =
        ref.read(labelsProvider).valueOrNull ?? const [];
    final int? picked = await showDialog<int?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Show tasks labelled'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('All'),
          ),
          for (final Label l in labels)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, l.id),
              child: Row(children: [
                Icon(Icons.circle, size: 12, color: Color(l.colorValue)),
                const SizedBox(width: 10),
                Text(l.name),
              ]),
            ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _filterLabelId = picked);
  }

  // ── List view ─────────────────────────────────────────────────────────

  Widget _buildList(BuildContext context, List<TaskModel> tasks) {
    final AsyncValue<List<HabitWithStatus>> habitsAsync =
        ref.watch(habitsForDateProvider(_dateStr));
    final (List<TaskModel> timed, List<TaskModel> untimed) =
        splitTimed(tasks);

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      children: [
        const _SectionLabel(label: 'Habits', icon: Icons.loop_rounded),
        ..._buildHabits(habitsAsync),
        const SizedBox(height: 4),
        if (timed.isNotEmpty) ...[
          const _SectionLabel(
              label: 'Scheduled', icon: Icons.schedule_rounded),
          ...timed.map((t) => TaskTile(task: t)),
        ],
        _SectionLabel(
            label: timed.isEmpty ? 'Tasks due' : 'Anytime',
            icon: Icons.task_alt_rounded),
        if (tasks.isEmpty)
          const _EmptyNote(text: 'Nothing due this day')
        else if (untimed.isEmpty)
          const _EmptyNote(text: 'Everything is scheduled 🎉')
        else
          ...untimed.map((t) => TaskTile(task: t)),
      ],
    );
  }

  List<Widget> _buildHabits(AsyncValue<List<HabitWithStatus>> async) {
    return async.when(
      skipLoadingOnReload: true,
      loading: () => const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (_, __) => const [_ErrorNote(text: 'Could not load habits')],
      data: (List<HabitWithStatus> habits) {
        if (habits.isEmpty) {
          return const [_EmptyNote(text: 'No habits created yet')];
        }
        return habits
            .map((h) => _HabitItem(item: h, date: _dateStr))
            .toList();
      },
    );
  }

  // ── Grid view ─────────────────────────────────────────────────────────

  Widget _buildGrid(List<TaskModel> tasks) {
    final shift = ref.watch(shiftsByDateProvider).valueOrNull?[_dateStr];
    final (List<TaskModel> _, List<TaskModel> untimed) = splitTimed(tasks);

    return Column(
      children: [
        if (untimed.isNotEmpty)
          ExpansionTile(
            dense: true,
            title: Text('Anytime · ${untimed.length}'),
            leading: const Icon(Icons.task_alt_rounded, size: 18),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            children: [for (final t in untimed) TaskTile(task: t)],
          ),
        Expanded(
          child: DayTimeGrid(
            dateStr: _dateStr,
            tasks: tasks,
            shift: shift,
          ),
        ),
      ],
    );
  }
}

// ── Habit item (interactive) ──────────────────────────────────────────────────

/// A tappable habit row for the planner day detail.
/// Toggling sets completion for [date] — not necessarily today.
class _HabitItem extends ConsumerWidget {
  const _HabitItem({required this.item, required this.date});

  final HabitWithStatus item;
  final String date; // "yyyy-MM-dd"

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool done = item.isDoneToday; // "isDoneOnDate" in planner context

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => ref
            .read(toggleCompletionProvider.notifier)
            .toggle(item.habit.id, date: date),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
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
                        size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.habit.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration:
                            done ? TextDecoration.lineThrough : null,
                        color: done
                            ? cs.onSurface.withAlpha(130)
                            : cs.onSurface,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared helper widgets ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(110),
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(text,
          style: TextStyle(color: Theme.of(context).colorScheme.error)),
    );
  }
}
