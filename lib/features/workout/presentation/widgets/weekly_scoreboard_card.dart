import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/group_score.dart';
import '../../data/models/muscle_groups.dart';
import '../providers/workout_providers.dart';

/// "This week" scoreboard: each muscle's sessions + sets vs target, auto-computed
/// from logged workouts and grouped under push/pull/… headers. Per-muscle so one
/// muscle can never be masked by another in the same group.
class WeeklyScoreboardCard extends ConsumerWidget {
  const WeeklyScoreboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<MuscleScore> scores = ref.watch(weeklyScoreboardProvider);

    final int metCount = scores.where((s) => s.fullyMet).length;
    final int total = scores.where((s) => s.frequencyTarget > 0).length;

    // Build rows: a group header whenever the group changes, then its muscles.
    final List<Widget> rows = [];
    String? lastGroup;
    for (final MuscleScore s in scores) {
      if (s.group != lastGroup) {
        rows.add(_GroupHeader(label: MuscleGroup.label(s.group)));
        lastGroup = s.group;
      }
      rows.add(_MuscleRow(score: s));
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
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
                  '$metCount / $total muscles',
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
            const SizedBox(height: 4),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: cs.onSurface.withAlpha(110),
        ),
      ),
    );
  }
}

class _MuscleRow extends StatelessWidget {
  const _MuscleRow({required this.score});
  final MuscleScore score;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    final Color accent = score.fullyMet
        ? Colors.green
        : (score.sessionsDone > 0 || score.setsDone > 0)
            ? const Color(0xFFF4A52A)
            : cs.onSurface.withAlpha(70);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: accent),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    score.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          _FrequencyDots(
            done: score.sessionsDone,
            target: score.frequencyTarget,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score.setsProgress,
                minHeight: 6,
                backgroundColor: cs.onSurface.withAlpha(20),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 54,
            child: Text(
              '${score.setsDone}/${score.setsTarget} sets',
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 11, color: cs.onSurface.withAlpha(170)),
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
