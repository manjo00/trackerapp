import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/workout_session_model.dart';
import '../../domain/workout_summary.dart';

/// One past workout in the history (look B, Ahmed's pick 2026-11-04): the
/// kilos lifted as a big number, then the name and date, its sets and records,
/// and how its kilos compare with [previous], the last workout of the same
/// plan. Tapping it opens the workout page.
class WorkoutHistoryTile extends StatelessWidget {
  const WorkoutHistoryTile({
    super.key,
    required this.session,
    this.previous,
    this.onTap,
  });

  final WorkoutSessionModel session;
  final WorkoutSessionModel? previous;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Color muted = cs.onSurface.withAlpha(150);
    final DateTime date = DateTime.tryParse(session.date) ?? session.createdAt;
    final double kg = kgLifted(session.sets);
    final int sets = loggedSetCount(session.sets);
    final int records = recordCount(session.sets);
    final WorkoutSessionModel? before = previous;
    final int? change =
        before == null ? null : percentChange(kg, kgLifted(before.sets));

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 68,
              child: Column(
                children: [
                  Text(
                    kg > 0 ? shortKg(kg) : '–',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text('lifted',
                      style: theme.textTheme.labelSmall?.copyWith(color: muted)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${session.displayName} · '
                    '${DateFormat('EEE, d MMM').format(date)}',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      '$sets ${sets == 1 ? 'set' : 'sets'}',
                      if (records > 0)
                        '$records ${records == 1 ? 'record' : 'records'}',
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  if (change != null && change != 0)
                    Text(
                      change > 0
                          ? '$change% more than last time'
                          : '${-change}% less than last time',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: change > 0 ? _better(theme) : muted),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
    );
  }
}

/// The green of "more than last time", readable in both themes.
Color _better(ThemeData theme) => theme.brightness == Brightness.dark
    ? Colors.green.shade300
    : Colors.green.shade700;
