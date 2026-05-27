import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/habits/data/models/habit_with_status.dart';
import '../../../../features/habits/presentation/providers/habits_providers.dart';
import '../../../../features/habits/presentation/widgets/habit_tile.dart';
import '../../../../features/tasks/data/models/task_model.dart';
import '../../../../features/tasks/presentation/providers/tasks_providers.dart';
import '../../../../features/tasks/presentation/widgets/task_tile.dart';

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
                // ── Overdue section (only shown when there are overdue items)
                ..._buildOverdueSection(context, overdueAsync),

                // ── Habits section ────────────────────────────────────────
                const _SectionHeader(
                  label: 'Habits',
                  icon: Icons.loop_rounded,
                ),
                ..._buildHabitsSection(habitsAsync),

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

// ── Overdue banner ────────────────────────────────────────────────────────────

class _OverdueSectionHeader extends StatelessWidget {
  const _OverdueSectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer.withAlpha(160),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 18, color: cs.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count overdue ${count == 1 ? 'task' : 'tasks'} — tackle these first',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onErrorContainer,
                    fontWeight: FontWeight.w600,
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
