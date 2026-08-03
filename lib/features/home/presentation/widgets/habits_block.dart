import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../habits/data/models/habit_with_status.dart';
import '../../../habits/presentation/providers/habits_providers.dart';
import '../../../habits/presentation/widgets/habit_tile.dart';

/// Home block: today's habits with their normal check-off tiles — a straight
/// reuse of the Habits screen's data + tile, so ticking here counts streaks
/// exactly the same way.
class HabitsBlock extends ConsumerWidget {
  const HabitsBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<HabitWithStatus> habits =
        ref.watch(habitsWithStatusProvider).valueOrNull ?? const [];

    if (habits.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            'No habits yet — add some from the drawer',
            style: TextStyle(fontSize: 13, color: cs.onSurface.withAlpha(110)),
          ),
        ),
      );
    }
    return Column(
      children: [for (final HabitWithStatus h in habits) HabitTile(item: h)],
    );
  }
}
