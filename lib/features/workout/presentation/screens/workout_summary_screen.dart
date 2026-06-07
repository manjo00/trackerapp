import 'package:flutter/material.dart';

/// Computed end-of-workout stats (plain record — no codegen).
typedef WorkoutSummary = ({
  Duration duration,
  int exerciseCount,
  int setCount,
  double totalVolume,
  int prCount,
  List<({String name, double? topWeight, int? topReps})> topSets,
});

/// Bottom sheet shown after finishing a workout: duration, exercises, total
/// volume lifted, new PRs, and a per-exercise top-set list.
class WorkoutSummarySheet extends StatelessWidget {
  const WorkoutSummarySheet({super.key, required this.summary});

  final WorkoutSummary summary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Row(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Text(
                  'Workout complete',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stat cards
            Row(
              children: [
                _StatCard(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: _fmtDuration(summary.duration),
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.fitness_center_rounded,
                  label: 'Exercises',
                  value: '${summary.exerciseCount}',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatCard(
                  icon: Icons.format_list_numbered_rounded,
                  label: 'Sets',
                  value: '${summary.setCount}',
                ),
                const SizedBox(width: 10),
                _StatCard(
                  icon: Icons.scale_rounded,
                  label: 'Volume',
                  value: '${_fmtNum(summary.totalVolume)} kg',
                ),
              ],
            ),

            if (summary.prCount > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text(
                      '${summary.prCount} new personal '
                      '${summary.prCount == 1 ? 'record' : 'records'}!',
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (summary.topSets.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Top sets',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: summary.topSets.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final t = summary.topSets[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.name),
                      trailing: Text(
                        '${_fmtNum(t.topWeight)} kg × ${t.topReps ?? '–'}',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: cs.primary),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  static String _fmtNum(double? n) {
    if (n == null) return '–';
    return n == n.truncateToDouble() ? '${n.toInt()}' : n.toStringAsFixed(1);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: cs.primary),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withAlpha(150))),
          ],
        ),
      ),
    );
  }
}
