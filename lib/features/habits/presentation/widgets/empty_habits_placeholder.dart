import 'package:flutter/material.dart';

/// Shown in [HabitListScreen] when the user has no habits yet.
///
/// A gentle nudge to add their first one — friendlier than an empty white screen.
class EmptyHabitsPlaceholder extends StatelessWidget {
  const EmptyHabitsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_task_rounded,
              size: 72,
              color: cs.primary.withAlpha(160),
            ),
            const SizedBox(height: 20),
            Text(
              'No habits yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap the + button to add your first habit and start building your streak.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withAlpha(160),
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
