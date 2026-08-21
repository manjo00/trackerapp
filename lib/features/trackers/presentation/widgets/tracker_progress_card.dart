import 'package:flutter/material.dart';
import '../../data/models/tracker_log_model.dart';

/// Card shown in the tracker list.
///
/// Displays the tracker icon, name, and a progress bar / count for today.
/// Tapping the card navigates to the detail screen; swiping it left archives
/// the tracker (with Undo) rather than destroying it and its whole log history.
class TrackerProgressCard extends StatelessWidget {
  const TrackerProgressCard({
    super.key,
    required this.tracker,
    required this.onTap,
    required this.onArchive,
  });

  final TrackerWithProgress tracker;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = Color(tracker.colorValue);

    // Progress fraction — clamped so we never exceed 1.0.
    final bool hasItems = tracker.totalItems > 0;
    final double fraction = hasItems
        ? (tracker.doneToday / tracker.totalItems).clamp(0.0, 1.0)
        : 0.0;

    final bool isSessionLog =
        tracker.totalItems == 0 && tracker.doneToday >= 0;
    // For session logs, totalItems is 0 — show a simple count badge instead.

    return Dismissible(
      key: ValueKey('tracker_${tracker.trackerId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: cs.tertiaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.archive_rounded, color: cs.onTertiaryContainer),
      ),
      // No confirm dialog: archiving is reversible and the snackbar offers
      // Undo, so a swipe never needs to stop and ask.
      onDismissed: (_) => onArchive(),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon bubble
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tracker.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tracker.name,
                            style: tt.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subtitle(tracker, isSessionLog),
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    // Progress badge
                    _ProgressBadge(
                      done: tracker.doneToday,
                      total: tracker.totalItems,
                      color: color,
                      isSession: isSessionLog,
                    ),
                  ],
                ),
                // Progress bar — only for checklists
                if (hasItems) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 6,
                      backgroundColor: color.withAlpha(30),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(TrackerWithProgress t, bool isSession) {
    if (isSession) {
      return t.doneToday == 0
          ? 'No sessions logged today'
          : '${t.doneToday} session${t.doneToday == 1 ? '' : 's'} today';
    }
    if (t.totalItems == 0) return 'No items — tap to add some';
    return '${t.doneToday} / ${t.totalItems} done today';
  }
}

class _ProgressBadge extends StatelessWidget {
  const _ProgressBadge({
    required this.done,
    required this.total,
    required this.color,
    required this.isSession,
  });

  final int done;
  final int total;
  final Color color;
  final bool isSession;

  @override
  Widget build(BuildContext context) {
    final bool complete = !isSession && total > 0 && done >= total;

    if (complete) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_circle_rounded, color: color, size: 20),
      );
    }

    if (isSession) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$done',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$done/$total',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
