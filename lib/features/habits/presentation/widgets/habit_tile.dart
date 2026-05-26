import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/habit_with_status.dart';
import '../providers/habits_providers.dart';
import 'streak_badge.dart';

/// A card representing one habit in the list.
///
/// Displays:
///   - Habit name
///   - Streak badge (hidden when streak is 0)
///   - Animated checkbox showing today's completion state
///
/// Tapping anywhere on the card (or the checkbox) calls [toggleCompletionProvider]
/// to insert or delete today's completion row.
///
/// Uses [ConsumerWidget] so it can call [ref.read] to trigger the toggle.
/// [ConsumerWidget] is Riverpod's version of [StatelessWidget] — it adds
/// the `ref` parameter to [build] so you can interact with providers.
class HabitTile extends ConsumerWidget {
  const HabitTile({required this.item, super.key});

  final HabitWithStatus item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool done = item.isDoneToday;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _toggle(ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // ── Checkbox ───────────────────────────────────────────────
              // AnimatedContainer smoothly transitions the checkbox fill
              // colour when the habit is toggled.
              GestureDetector(
                onTap: () => _toggle(ref),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? cs.primary : Colors.transparent,
                    border: Border.all(
                      color: done ? cs.primary : cs.outline,
                      width: 2,
                    ),
                  ),
                  child: done
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),

              const SizedBox(width: 14),

              // ── Habit name ─────────────────────────────────────────────
              Expanded(
                child: Text(
                  item.habit.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        // Strikethrough when done — subtle visual feedback.
                        decoration:
                            done ? TextDecoration.lineThrough : null,
                        color: done
                            ? cs.onSurface.withAlpha(130)
                            : cs.onSurface,
                      ),
                ),
              ),

              const SizedBox(width: 8),

              // ── Streak badge ───────────────────────────────────────────
              StreakBadge(streak: item.streak),
            ],
          ),
        ),
      ),
    );
  }

  void _toggle(WidgetRef ref) {
    ref
        .read(toggleCompletionProvider.notifier)
        .toggle(item.habit.id);
  }
}
