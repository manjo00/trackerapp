import 'package:flutter/material.dart';

/// Shown in [TaskListScreen] when there are no tasks yet.
class EmptyTasksPlaceholder extends StatelessWidget {
  const EmptyTasksPlaceholder({super.key});

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
              Icons.check_box_outline_blank_rounded,
              size: 72,
              color: cs.primary.withAlpha(160),
            ),
            const SizedBox(height: 20),
            Text(
              'No tasks yet',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap the + button to add your first task.',
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
