import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/settings/settings_provider.dart';
import '../../../coach/data/coach_tip.dart';
import '../../../coach/presentation/coach_controller.dart';
import '../../../shifts/data/models/work_shift_model.dart';
import '../../../shifts/presentation/providers/shifts_providers.dart';
import '../../domain/habit_day.dart';
import '../../domain/habit_rules.dart';
import '../models/habit_day_view.dart';
import '../providers/habits_providers.dart';
import '../widgets/habit_sections.dart';
import '../widgets/habits_week_strip.dart';

/// The Habits screen in Look A: today's date and shift, how many are done,
/// the week strip, then what is left by part of the day, with "Done today"
/// and "Not due today" folded at the bottom.
///
/// Tapping a past day in the strip (this week or last week) shows that day
/// instead, to tick what was done but not ticked. "Back to today" returns to
/// today, and so does leaving: another tab or a screen on top (this tab stays
/// alive behind them), or the app going to the background.
class HabitListScreen extends ConsumerStatefulWidget {
  const HabitListScreen({super.key});

  @override
  ConsumerState<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends ConsumerState<HabitListScreen> {
  /// The past day picked in the week strip, or null for today.
  String? _picked;

  /// The strip's week: 0 this week, -1 last week.
  int _weekOffset = 0;

  /// Whether this tab was in front at the last check (its tickers run).
  bool _inFront = true;

  late final AppLifecycleListener _lifecycle =
      AppLifecycleListener(onResume: _backToToday);

  @override
  void initState() {
    super.initState();
    _lifecycle; // starts listening
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Another tab or a screen on top stops this tab's tickers; coming back
    // to the front shows today again (a build follows, so no setState).
    final bool inFront = TickerMode.valuesOf(context).enabled;
    if (inFront && !_inFront) {
      _picked = null;
      _weekOffset = 0;
    }
    _inFront = inFront;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _backToToday() {
    if (_picked == null && _weekOffset == 0) return;
    setState(() {
      _picked = null;
      _weekOffset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<HabitDayView>> viewsAsync =
        ref.watch(habitDayViewsProvider);
    final String today = ref.watch(habitTodayProvider);
    final bool weekStartsSunday =
        ref.watch(settingsProvider.select((s) => s.weekStartsSunday));
    // A picked day that the turning day left out of reach shows today.
    final String? picked = _picked;
    final String shown = picked != null &&
            isPickableDay(picked,
                today: today, weekStartsSunday: weekStartsSunday)
        ? picked
        : today;

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
          data: (List<HabitDayView> views) {
            if (views.isEmpty) return const _EmptyHabits();
            final List<HabitDayView> shownViews = shown == today
                ? views
                : [
                    for (final HabitDayView v in views)
                      v.onDay(shown,
                          today: today, weekStartsSunday: weekStartsSunday),
                  ];
            return ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 96),
              children: [
                _DayLine(
                    views: shownViews,
                    day: shown,
                    onBackToToday: _backToToday),
                HabitsWeekStrip(
                  views: views,
                  today: today,
                  shifts:
                      ref.watch(shiftsByDateProvider).valueOrNull ?? const {},
                  weekStartsSunday: weekStartsSunday,
                  selected: shown,
                  weekOffset: _weekOffset,
                  onPick: (String day) =>
                      setState(() => _picked = day == today ? null : day),
                  onWeek: (int offset) =>
                      setState(() => _weekOffset = offset),
                ),
                // Keyed by the day, so a new day starts with its folds
                // closed and nothing lingering from the day before.
                HabitSections(
                  key: ValueKey('habit-sections-$shown'),
                  views: shownViews,
                  dayLabel: shown == today
                      ? null
                      : DateFormat('EEE').format(DateTime.parse(shown)),
                ),
              ],
            );
          },
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

/// "Wed 4 Nov  [Day off]        2 of 6 done", or for a picked past day
/// "Yesterday · Tue 3 Nov        [Back to today]". Both are 32 high, so the
/// strip under it doesn't jump when the day changes.
class _DayLine extends ConsumerWidget {
  const _DayLine(
      {required this.views, required this.day, required this.onBackToToday});

  final List<HabitDayView> views;

  /// The day the list shows.
  final String day;

  final VoidCallback onBackToToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String today = ref.watch(habitTodayProvider);
    if (day != today) {
      final String date = DateFormat('EEE d MMM').format(DateTime.parse(day));
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 12, 10),
        child: SizedBox(
          height: 32,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  day == addDays(today, -1) ? 'Yesterday · $date' : date,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface, fontWeight: FontWeight.w500),
                ),
              ),
              FilledButton.tonal(
                onPressed: onBackToToday,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Text('Back to today'),
              ),
            ],
          ),
        ),
      );
    }
    final Map<String, WorkShiftModel>? shifts =
        ref.watch(shiftsByDateProvider).valueOrNull;
    final int kept = views.where((v) => v.state == DayState.kept).length;
    final int due = views
        .where((v) => const {DayState.kept, DayState.pending, DayState.partial}
            .contains(v.state))
        .length;
    final TextStyle? style =
        Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            Text(DateFormat('EEE d MMM').format(DateTime.parse(today)),
                style: style),
            const SizedBox(width: 8),
            if (shifts != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
