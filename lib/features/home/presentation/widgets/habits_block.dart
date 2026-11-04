import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../habits/domain/habit_rules.dart';
import '../../../habits/presentation/models/habit_day_view.dart';
import '../../../habits/presentation/providers/habits_providers.dart';
import '../../../habits/presentation/widgets/habit_row.dart';

/// Home block: the habits still to do today, as the same Look A rows the
/// Habits screen uses (so a tick here counts exactly the same), and a line
/// saying how many are already done.
class HabitsBlock extends ConsumerWidget {
  const HabitsBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<HabitDayView> views =
        ref.watch(habitDayViewsProvider).valueOrNull ?? const [];
    final TextStyle hint =
        TextStyle(fontSize: 13, color: cs.onSurface.withAlpha(110));

    if (views.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text('No habits yet — add some from the drawer', style: hint),
        ),
      );
    }
    final List<HabitDayView> open = [
      for (final HabitDayView v in views)
        if (v.summary.today == DayState.pending ||
            v.summary.today == DayState.partial)
          v,
    ];
    final int done =
        views.where((v) => v.summary.today == DayState.kept).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final HabitDayView v in open)
          HabitRow(key: ValueKey('home-${v.habit.id}'), view: v),
        if (done > 0 || open.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              open.isEmpty && done == 0
                  ? 'Nothing due today'
                  : open.isEmpty
                      ? 'All done today · $done'
                      : '$done done',
              style: hint,
            ),
          ),
      ],
    );
  }
}
