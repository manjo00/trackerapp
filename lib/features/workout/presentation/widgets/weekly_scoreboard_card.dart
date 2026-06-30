import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/group_score.dart';
import '../providers/workout_providers.dart';

/// "This week" scoreboard: each muscle group's sessions + sets vs target,
/// auto-computed from logged workouts. The heart of the weekly-target system.
class WeeklyScoreboardCard extends ConsumerWidget {
  const WeeklyScoreboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<GroupScore> scores = ref.watch(weeklyScoreboardProvider);

    final int metCount = scores.where((s) => s.fullyMet).length;
    final int total = scores.where((s) => s.frequencyTarget > 0).length;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes_rounded, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'This week',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Text(
                  '$metCount / $total goals',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: metCount == total && total > 0
                        ? Colors.green
                        : cs.onSurface.withAlpha(150),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final GroupScore s in scores) _GroupRow(score: s),
          ],
        ),
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.score});
  final GroupScore score;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    // Status colour: green = met, amber = in progress, grey = nothing yet.
    final Color accent = score.fullyMet
        ? Colors.green
        : (score.sessionsDone > 0 || score.setsDone > 0)
            ? const Color(0xFFF4A52A)
            : cs.onSurface.withAlpha(70);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Label + status dot
          SizedBox(
            width: 78,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    score.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Frequency dots
          _FrequencyDots(
            done: score.sessionsDone,
            target: score.frequencyTarget,
            color: accent,
          ),
          const SizedBox(width: 10),
          // Sets progress bar + count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score.setsProgress,
                    minHeight: 6,
                    backgroundColor: cs.onSurface.withAlpha(20),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 54,
            child: Text(
              '${score.setsDone}/${score.setsTarget} sets',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withAlpha(170),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows [target] dots; the first [done] are filled. Extra sessions beyond the
/// target add a small "+N".
class _FrequencyDots extends StatelessWidget {
  const _FrequencyDots({
    required this.done,
    required this.target,
    required this.color,
  });

  final int done;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int extra = done > target ? done - target : 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < target; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < done ? color : Colors.transparent,
                border: Border.all(
                  color: i < done ? color : cs.onSurface.withAlpha(60),
                  width: 1.4,
                ),
              ),
            ),
          ),
        if (extra > 0)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Text(
              '+$extra',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: color),
            ),
          ),
      ],
    );
  }
}
