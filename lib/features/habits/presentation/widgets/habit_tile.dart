import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../archive/presentation/archive_providers.dart';
import '../../data/models/habit_with_status.dart';
import '../providers/habits_providers.dart';
import 'streak_badge.dart';

/// A card representing one habit in the list.
///
/// Interactions:
///   • Tap anywhere   → toggle today's completion
///   • Long-press     → open edit screen (pre-filled, and where Delete lives)
///   • Swipe left     → archive, with Undo. Nothing is destroyed by a swipe:
///                      a mis-swipe can't cost you months of streak.
class HabitTile extends ConsumerWidget {
  const HabitTile({required this.item, super.key});

  final HabitWithStatus item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool done = item.isDoneToday;

    return Dismissible(
      key: ValueKey(item.habit.id),
      direction: DismissDirection.endToStart,
      // Amber background with an archive icon revealed on left-swipe.
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: cs.tertiaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.archive_rounded, color: cs.onTertiaryContainer),
      ),
      onDismissed: (_) => _archive(context, ref),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggle(ref),
          onLongPress: () =>
              context.push('/habits/edit', extra: item.habit),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // ── Checkbox ──────────────────────────────────────────────
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
      ),
    );
  }

  void _toggle(WidgetRef ref) {
    ref
        .read(toggleCompletionProvider.notifier)
        .toggle(item.habit.id);
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final ArchiveService svc = ref.read(archiveServiceProvider);
    await svc.archiveHabit(item.habit.id, DateTime.now());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${item.habit.name}" archived'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => svc.restoreHabit(item.habit.id),
          ),
        ),
      );
    }
  }
}
