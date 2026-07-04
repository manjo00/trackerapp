import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../tasks/data/models/task_model.dart';
import '../../../tasks/presentation/providers/lists_providers.dart';
import '../../../tasks/presentation/providers/tasks_providers.dart';
import '../../../tasks/presentation/widgets/task_tile.dart';

/// The app's landing dashboard (replaced the Inbox tab).
///
/// v1 = four fixed blocks; the customizable block engine (saved filters,
/// pinned lists, habit blocks…) is the next slice of the plan.
///   1. Urgent    — overdue + high-priority due within 2 days (red)
///   2. Due today — today's remaining tasks not already shown above
///   3. Captured  — tasks not filed under any list (quick-add lands here)
///   4. This week — compact 7-day strip, taps through to the Planner
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    final List<TaskModel> urgent = ref.watch(urgentTasksProvider);
    final Set<int> urgentIds = urgent.map((t) => t.id).toSet();

    final List<TaskModel> dueToday =
        (ref.watch(tasksDueTodayProvider).valueOrNull ?? const [])
            .where((t) => !urgentIds.contains(t.id))
            .toList();

    final Set<int> shownIds = {...urgentIds, ...dueToday.map((t) => t.id)};
    final List<TaskModel> captured =
        (ref.watch(capturedTasksProvider).valueOrNull ?? const [])
            .where((t) => !shownIds.contains(t.id))
            .toList();

    final List<TaskModel> week =
        ref.watch(thisWeekTasksProvider).valueOrNull ?? const [];

    final bool allClear =
        urgent.isEmpty && dueToday.isEmpty && captured.isEmpty && week.isEmpty;

    return Scaffold(
      body: allClear
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 10),
                  Text(
                    'All clear',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nothing urgent, nothing captured',
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurface.withAlpha(120)),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                if (urgent.isNotEmpty)
                  _HomeBlock(
                    title: 'Urgent',
                    icon: Icons.local_fire_department_rounded,
                    color: cs.error,
                    tasks: urgent,
                  ),
                if (dueToday.isNotEmpty)
                  _HomeBlock(
                    title: 'Due today',
                    icon: Icons.today_rounded,
                    color: cs.primary,
                    tasks: dueToday,
                  ),
                if (captured.isNotEmpty)
                  _HomeBlock(
                    title: 'Captured',
                    icon: Icons.inbox_rounded,
                    color: cs.tertiary,
                    tasks: captured,
                  ),
                if (week.isNotEmpty) _WeekStrip(tasks: week),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () => context.push('/tasks/add'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ── One titled block of task tiles ────────────────────────────────────────

class _HomeBlock extends StatelessWidget {
  const _HomeBlock({
    required this.title,
    required this.icon,
    required this.color,
    required this.tasks,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<TaskModel> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                '${tasks.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color.withAlpha(150),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        ...tasks.map((t) => TaskTile(task: t, showListName: true)),
      ],
    );
  }
}

// ── This-week strip ───────────────────────────────────────────────────────

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.tasks});

  final List<TaskModel> tasks;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final DateTime today = DateTime.now();

    // Group the (already date-sorted) range stream per day.
    final Map<String, List<TaskModel>> byDate = {};
    for (final TaskModel t in tasks) {
      final String? d = t.dueDate;
      if (d != null) (byDate[d] ??= []).add(t);
    }

    const List<String> weekdays = [
      '', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
          child: Row(
            children: [
              Icon(Icons.view_week_rounded, size: 16, color: cs.secondary),
              const SizedBox(width: 6),
              Text(
                'THIS WEEK',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.secondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              for (int i = 0; i < 7; i++)
                _dayRow(
                  context,
                  DateTime(today.year, today.month, today.day + i),
                  byDate,
                  weekdays,
                  isToday: i == 0,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dayRow(BuildContext context, DateTime day,
      Map<String, List<TaskModel>> byDate, List<String> weekdays,
      {required bool isToday}) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String key = '${day.year}-${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
    final List<TaskModel> dayTasks = byDate[key] ?? const [];
    if (dayTasks.isEmpty && !isToday) return const SizedBox.shrink();

    final String preview =
        dayTasks.take(2).map((t) => t.title).join(' · ');

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
