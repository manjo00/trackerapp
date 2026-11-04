import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/settings/settings_provider.dart';
import '../../../coach/data/coach_tip.dart';
import '../../../coach/presentation/coach_controller.dart';
import '../../../shifts/data/models/work_shift_model.dart';
import '../../../shifts/presentation/providers/shifts_providers.dart';
import '../../domain/habit_rules.dart';
import '../models/habit_day_view.dart';
import '../providers/habits_providers.dart';
import '../widgets/habit_sections.dart';
import '../widgets/habits_week_strip.dart';

/// The Habits screen in Look A: today's date and shift, how many are done,
/// the week strip, then what is left by part of the day, with "Done today"
/// and "Not due today" folded at the bottom.
class HabitListScreen extends ConsumerWidget {
  const HabitListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<HabitDayView>> viewsAsync =
        ref.watch(habitDayViewsProvider);

    return CoachMarks(
      screen: kCoachHabits,
      child: Scaffold(
        body: viewsAsync.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object err, StackTrace _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Something went wrong:\n$err',
                  textAlign: TextAlign.center),
            ),
          ),
          data: (List<HabitDayView> views) => views.isEmpty
              ? const _EmptyHabits()
              : ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 96),
                  children: [
                    _DayLine(views: views),
                    HabitsWeekStrip(
                      views: views,
                      today: ref.watch(habitTodayProvider),
                      shifts: ref.watch(shiftsByDateProvider).valueOrNull ??
                          const {},
                      weekStartsSunday: ref.watch(
                          settingsProvider.select((s) => s.weekStartsSunday)),
                    ),
                    HabitSections(views: views),
                  ],
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/habits/add'),
          tooltip: 'Add habit',
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }
}

/// "Wed 4 Nov  [Day off]        2 of 6 done".
class _DayLine extends ConsumerWidget {
  const _DayLine({required this.views});

  final List<HabitDayView> views;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String today = ref.watch(habitTodayProvider);
    final Map<String, WorkShiftModel>? shifts =
        ref.watch(shiftsByDateProvider).valueOrNull;
    final int kept =
        views.where((v) => v.summary.today == DayState.kept).length;
    final int due = views
        .where((v) => const {DayState.kept, DayState.pending, DayState.partial}
            .contains(v.summary.today))
        .length;
    final TextStyle? style =
        Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          Text(DateFormat('EEE d MMM').format(DateTime.parse(today)),
              style: style),
          const SizedBox(width: 8),
          if (shifts != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                switch (shifts[today]?.type) {
                  ShiftType.day => 'Day shift',
                  ShiftType.night => 'Night shift',
                  null => 'Day off',
                },
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          const Spacer(),
          if (due > 0) Text('$kept of $due done', style: style),
        ],
      ),
    );
  }
}

class _EmptyHabits extends StatelessWidget {
  const _EmptyHabits();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_task_rounded, size: 56, color: cs.primary),
            const SizedBox(height: 16),
            Text('No habits yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Pick something small you want to do most days. '
              'A missed day never wipes out your progress.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.push('/habits/add'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add your first habit'),
            ),
          ],
        ),
      ),
    );
  }
}
