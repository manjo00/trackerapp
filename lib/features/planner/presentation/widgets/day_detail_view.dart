import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/habits/data/models/habit_with_status.dart';
import '../../../../features/habits/presentation/providers/habits_providers.dart';
import '../../../../features/tasks/data/models/task_model.dart';
import '../../../../features/tasks/presentation/widgets/task_tile.dart';
import '../providers/planner_providers.dart';

/// Scrollable content area showing habits and tasks for [selectedDate].
///
/// Habits are tappable — tapping toggles completion for that specific date
/// (not necessarily today). Tasks reuse the existing [TaskTile] which already
/// handles toggling via its own provider.
class DayDetailView extends ConsumerWidget {
  const DayDetailView({required this.selectedDate, super.key});

  final DateTime selectedDate;

  String get _dateStr =>
      '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<HabitWithStatus>> habitsAsync =
        ref.watch(habitsForDateProvider(_dateStr));
    final AsyncValue<List<TaskModel>> tasksAsync =
        ref.watch(tasksForDateProvider(_dateStr));

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 80),
      children: [
        // ── Habits section ─────────────────────────────────────────────────
        const _SectionLabel(label: 'Habits', icon: Icons.loop_rounded),
        ..._buildHabits(context, ref, habitsAsync),

        const SizedBox(height: 4),

        // ── Tasks section ──────────────────────────────────────────────────
        const _SectionLabel(label: 'Tasks due', icon: Icons.task_alt_rounded),
        ..._buildTasks(tasksAsync),
      ],
    );
  }

  // ── Section builders ────────────────────────────────────────────────────

  List<Widget> _buildHabits(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<HabitWithStatus>> async,
  ) {
    return async.when(
      skipLoadingOnReload: true,
      loading: () => [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (_, __) => [const _ErrorNote(text: 'Could not load habits')],
      data: (List<HabitWithStatus> habits) {
        if (habits.isEmpty) {
          return [const _EmptyNote(text: 'No habits created yet')];
        }
        return habits
            .map(
              (h) => _HabitItem(
                item: h,
                date: _dateStr,
              ),
            )
            .toList();
      },
    );
  }

  List<Widget> _buildTasks(AsyncValue<List<TaskModel>> async) {
    return async.when(
      skipLoadingOnReload: true,
      loading: () => [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (_, __) => [const _ErrorNote(text: 'Could not load tasks')],
      data: (List<TaskModel> tasks) {
        if (tasks.isEmpty) {
          return [const _EmptyNote(text: 'Nothing due this day')];
        }
        return tasks.map((t) => TaskTile(task: t)).toList();
      },
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
        onTap: () =>
            ref.read(toggleCompletionProvider.notifier).toggle(
                  item.habit.id,
                  date: date,
                ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Animated circle checkbox
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
              color:
                  Theme.of(context).colorScheme.onSurface.withAlpha(110),
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
          style:
              TextStyle(color: Theme.of(context).colorScheme.error)),
    );
  }
}
