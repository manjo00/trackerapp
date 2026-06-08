import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/habits/data/models/habit_with_status.dart';
import '../../../../features/habits/presentation/providers/habits_providers.dart';
import '../../../../features/habits/presentation/widgets/habit_tile.dart';
import '../../../../features/tasks/data/models/task_model.dart';
import '../../../../features/tasks/presentation/providers/tasks_providers.dart';
import '../../../../features/tasks/presentation/widgets/task_tile.dart';
import '../../../../features/trackers/data/models/tracker_item_model.dart';
import '../../../../features/trackers/data/models/tracker_today_status.dart';
import '../../../../features/trackers/presentation/providers/trackers_providers.dart';
import '../../../../features/workout/data/models/program_session_model.dart';
import '../../../../features/workout/presentation/providers/program_providers.dart';
import '../../../../features/workout/presentation/providers/workout_providers.dart';

/// The "Today" tab — shows today's habits, overdue tasks, and tasks due today.
///
/// Watches three independent providers in parallel:
///   • [habitsWithStatusProvider]  — all habits with today's completion state
///   • [overdueTasksProvider]      — incomplete tasks past their due date
///   • [tasksDueTodayProvider]     — incomplete tasks whose due date is today
///
/// Each section renders as soon as its data arrives; a single spinner is
/// shown only while ALL three are still on their first load.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<HabitWithStatus>> habitsAsync =
        ref.watch(habitsWithStatusProvider);
    final AsyncValue<List<TaskModel>> overdueAsync =
        ref.watch(overdueTasksProvider);
    final AsyncValue<List<TaskModel>> todayAsync =
        ref.watch(tasksDueTodayProvider);
    final AsyncValue<List<TrackerTodayStatus>> trackersAsync =
        ref.watch(checklistTrackersForTodayProvider);
    final suggestedSession =
        ref.watch(todaysSuggestedSessionProvider).valueOrNull;
    final activeWorkout = ref.watch(activeWorkoutProvider).valueOrNull;

    // Show a single spinner only while everything is still on its first load.
    final bool allLoading = habitsAsync is AsyncLoading &&
        overdueAsync is AsyncLoading &&
        todayAsync is AsyncLoading;

    return Scaffold(
      body: allLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              children: [
                // ── Workout session for today ──────────────────────────────
                if (suggestedSession != null || activeWorkout != null)
                  _buildWorkoutSection(
                      context, ref, suggestedSession, activeWorkout),

                // ── Overdue section (only shown when there are overdue items)
                ..._buildOverdueSection(context, overdueAsync),

                // ── Habits section ────────────────────────────────────────
                const _SectionHeader(
                  label: 'Habits',
                  icon: Icons.loop_rounded,
                ),
                ..._buildHabitsSection(habitsAsync),

                // ── Trackers section (daily checklists only) ──────────────
                ..._buildTrackersSection(trackersAsync),

                const SizedBox(height: 8),

                // ── Tasks due today section ───────────────────────────────
                const _SectionHeader(
                  label: 'Due today',
                  icon: Icons.task_alt_rounded,
                ),
                ..._buildTasksSection(todayAsync),

                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildWorkoutSection(
    BuildContext context,
    WidgetRef ref,
    ProgramSessionModel? suggested,
    dynamic activeWorkout,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(label: 'Workout', icon: Icons.fitness_center_rounded),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: activeWorkout != null
              ? _WorkoutTile(
                  label: 'Workout in progress',
                  subtitle: 'Tap to resume',
                  color: cs.tertiaryContainer,
                  iconColor: cs.onTertiaryContainer,
                  onTap: () => context.push('/workout/active'),
                  onCheck: null, // can't quick-complete an in-progress workout
                )
              : _WorkoutTile(
                  label: suggested != null ? suggested.name : 'Open Workout',
                  subtitle: suggested != null
                      ? '${suggested.exercises.length} exercises planned'
                      : 'No session scheduled today',
                  color: Color(suggested?.colorValue ?? 0xFF6750A4).withAlpha(30),
                  iconColor: Color(suggested?.colorValue ?? 0xFF6750A4),
                  onTap: () => context.go('/workout'),
                  onCheck: suggested != null
                      ? () => _startWorkout(context, ref, suggested)
                      : null,
                ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Future<void> _startWorkout(
      BuildContext context, WidgetRef ref, ProgramSessionModel session) async {
    await ref.read(activeWorkoutProvider.notifier).start(
          programSessionId: session.id,
          programExercises: session.exercises,
          programSessionName: session.name,
        );
    if (context.mounted) context.push('/workout/active');
  }

  // ── Section builders ────────────────────────────────────────────────────────

  List<Widget> _buildOverdueSection(
      BuildContext context, AsyncValue<List<TaskModel>> overdueAsync) {
    // Don't render the section at all while loading or on error —
    // the overdue banner should only appear when there's something to show.
    return overdueAsync.when(
      loading: () => [],
      error: (_, __) => [],
      data: (List<TaskModel> tasks) {
        if (tasks.isEmpty) return [];
        return [
          _OverdueSectionHeader(count: tasks.length),
          ...tasks.map((t) => TaskTile(task: t)),
          const SizedBox(height: 8),
        ];
      },
    );
  }

  List<Widget> _buildHabitsSection(
      AsyncValue<List<HabitWithStatus>> habitsAsync) {
    return habitsAsync.when(
      loading: () => [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (Object err, StackTrace _) => [
        const _ErrorTile(message: 'Could not load habits'),
      ],
      data: (List<HabitWithStatus> habits) {
        if (habits.isEmpty) {
          return [const _EmptyNote(text: 'No habits set up yet')];
        }
        return habits.map((h) => HabitTile(item: h)).toList();
      },
    );
  }

  List<Widget> _buildTrackersSection(
      AsyncValue<List<TrackerTodayStatus>> trackersAsync) {
    // Only render when there's something to show — silently hidden otherwise.
    return trackersAsync.when(
      loading: () => [],
      error: (_, __) => [],
      data: (List<TrackerTodayStatus> trackers) {
        if (trackers.isEmpty) return [];
        return [
          const _SectionHeader(
            label: 'Trackers',
            icon: Icons.bar_chart_rounded,
          ),
          ...trackers.map(
            (t) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _TrackerInlineCard(status: t),
            ),
          ),
          const SizedBox(height: 4),
        ];
      },
    );
  }

  List<Widget> _buildTasksSection(AsyncValue<List<TaskModel>> tasksAsync) {
    return tasksAsync.when(
      loading: () => [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (Object err, StackTrace _) => [
        const _ErrorTile(message: 'Could not load tasks'),
      ],
      data: (List<TaskModel> tasks) {
        if (tasks.isEmpty) {
          return [const _EmptyNote(text: 'Nothing due today  🎉')];
        }
        return tasks.map((t) => TaskTile(task: t)).toList();
      },
    );
  }
}

// ── Overdue section header ────────────────────────────────────────────────────

class _OverdueSectionHeader extends StatelessWidget {
  const _OverdueSectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    // A muted amber-red — visible but not jarring.
    const Color overdueColor = Color(0xFFB85C5C);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: overdueColor),
          const SizedBox(width: 6),
          Text(
            'OVERDUE',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: overdueColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: overdueColor.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: overdueColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

// ── Tracker inline card ───────────────────────────────────────────────────────

/// An expandable card for a daily-checklist tracker shown on Today.
///
/// The header shows the tracker name + "X/Y" progress badge; tapping it
/// toggles the item list. Each item has a circular checkbox that saves
/// the new check state to the DB immediately on tap.
///
/// Local [_checkedIds] state gives instant visual feedback without waiting
/// for the Riverpod stream to re-emit. [didUpdateWidget] syncs back from
/// the stream when external changes arrive (e.g. from the Trackers tab).
class _TrackerInlineCard extends ConsumerStatefulWidget {
  const _TrackerInlineCard({required this.status});

  final TrackerTodayStatus status;

  @override
  ConsumerState<_TrackerInlineCard> createState() => _TrackerInlineCardState();
}

class _TrackerInlineCardState extends ConsumerState<_TrackerInlineCard> {
  bool _expanded = false;
  late Set<int> _checkedIds;

  @override
  void initState() {
    super.initState();
    _checkedIds = Set.from(widget.status.checkedItemIds);
  }

  @override
  void didUpdateWidget(_TrackerInlineCard old) {
    super.didUpdateWidget(old);
    // Sync from the stream so changes made on the Trackers detail screen
    // are reflected here when the Today tab is revisited.
    _checkedIds = Set.from(widget.status.checkedItemIds);
  }

  void _toggle(int itemId) {
    final Set<int> updated = Set.from(_checkedIds);
    if (updated.contains(itemId)) {
      updated.remove(itemId);
    } else {
      updated.add(itemId);
    }
    setState(() => _checkedIds = updated);
    // Persist immediately — logChecklist does a full replace for today.
    ref.read(logChecklistProvider.notifier).save(
          trackerId: widget.status.trackerId,
          checkedItemIds: updated,
          allItems: widget.status.items,
        );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color accent = Color(widget.status.colorValue);
    final bool allDone = _checkedIds.length == widget.status.totalItems &&
        widget.status.totalItems > 0;

    return Card(
      child: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text(widget.status.icon,
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.status.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: allDone
                                ? cs.onSurface.withAlpha(130)
                                : cs.onSurface,
                            decoration: allDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                  ),
                  // X/Y progress badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: allDone
                          ? accent.withAlpha(40)
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_checkedIds.length}/${widget.status.totalItems}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: allDone ? accent : cs.onSurface.withAlpha(160),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Animated chevron rotates 90° when expanded.
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurface.withAlpha(120),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Item list (animated height) ────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _expanded
                ? Column(
                    children: [
                      Divider(height: 1, color: cs.outlineVariant),
                      ...widget.status.items.map((TrackerItemModel item) {
                        final bool done = _checkedIds.contains(item.id);
                        return ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          leading: GestureDetector(
                            onTap: () => _toggle(item.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done ? accent : Colors.transparent,
                                border: Border.all(
                                  color: done ? accent : cs.outline,
                                  width: 2,
                                ),
                              ),
                              child: done
                                  ? const Icon(Icons.check_rounded,
                                      size: 13, color: Colors.white)
                                  : null,
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: done
                                  ? cs.onSurface.withAlpha(130)
                                  : cs.onSurface,
                              decoration:
                                  done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          onTap: () => _toggle(item.id),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// A tappable workout row in the Today list.
/// [onCheck] is null when there's nothing to start (rest day / in-progress).
class _WorkoutTile extends StatelessWidget {
  const _WorkoutTile({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.iconColor,
    required this.onTap,
    required this.onCheck,
  });

  final String label;
  final String subtitle;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;
  final VoidCallback? onCheck;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.fitness_center_rounded, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurface.withAlpha(150)),
                    ),
                  ],
                ),
              ),
              if (onCheck != null)
                IconButton(
                  icon: Icon(Icons.play_arrow_rounded, color: iconColor),
                  tooltip: 'Start workout',
                  onPressed: onCheck,
                )
              else
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSurface.withAlpha(120)),
            ],
          ),
        ),
      ),
    );
  }
}
