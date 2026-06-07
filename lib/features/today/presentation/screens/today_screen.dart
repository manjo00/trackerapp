import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/habits/data/models/habit_with_status.dart';
import '../../../../features/habits/presentation/providers/habits_providers.dart';
import '../../../../features/habits/presentation/widgets/habit_tile.dart';
import '../../../../features/tasks/data/models/task_model.dart';
import '../../../../features/tasks/presentation/providers/tasks_providers.dart';
import '../../../../features/tasks/presentation/widgets/task_tile.dart';
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
