import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/habits/data/models/habit_with_status.dart';
import '../../../../features/habits/presentation/providers/habits_providers.dart';
import '../../../../features/habits/presentation/widgets/habit_tile.dart';
import '../../../../features/tasks/data/models/task_model.dart';
import '../../../../features/tasks/presentation/providers/tasks_providers.dart';
import '../../../../features/tasks/presentation/widgets/task_tile.dart';

/// The "Today" tab — shows today's habits and tasks due today in one place.
///
/// Watches two separate providers:
///   • [habitsWithStatusProvider]  — all habits with today's completion state
///   • [tasksDueTodayProvider]     — incomplete tasks whose due date is today
///
/// The two providers are independent. Rather than blocking the whole screen
/// until both resolve, we load them in parallel and render each section
/// as soon as its data arrives — with a fallback spinner while both are
/// still loading.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  // ── Date helpers ─────────────────────────────────────────────────────────

  static String _formattedDate(DateTime d) {
    const List<String> weekdays = [
      '', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    const List<String> months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${weekdays[d.weekday]}, ${months[d.month]} ${d.day}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<HabitWithStatus>> habitsAsync =
        ref.watch(habitsWithStatusProvider);
    final AsyncValue<List<TaskModel>> tasksAsync =
        ref.watch(tasksDueTodayProvider);

    // If both providers are still on their first load, show a single spinner
    // rather than two separate loading indicators — cleaner first impression.
    final bool bothLoading =
        habitsAsync is AsyncLoading && tasksAsync is AsyncLoading;

    final DateTime today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        // Two-line title: "Today" large + date small below.
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Today'),
            Text(
              _formattedDate(today),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(140),
                  ),
            ),
          ],
        ),
      ),

      body: bothLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              children: [
                // ── Habits section ───────────────────────────────────────
                const _SectionHeader(
                  label: 'Habits',
                  icon: Icons.loop_rounded,
                ),
                ..._buildHabitsSection(habitsAsync),

                const SizedBox(height: 8),

                // ── Tasks due today section ──────────────────────────────
                const _SectionHeader(
                  label: 'Due today',
                  icon: Icons.task_alt_rounded,
                ),
                ..._buildTasksSection(tasksAsync),

                const SizedBox(height: 16),
              ],
            ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────

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
        return habits
            .map((HabitWithStatus h) => HabitTile(item: h))
            .toList();
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
        return tasks.map((TaskModel t) => TaskTile(task: t)).toList();
      },
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
