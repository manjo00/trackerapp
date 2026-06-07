import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/workout_repository.dart';
import '../providers/workout_providers.dart';

/// Bottom sheet that lets the user load a set's weight/reps from history.
///
/// Two tabs:
///   • **Recent** — past sets for this exercise, newest first, with dates.
///   • **Max**    — heaviest sets ever, for quickly matching a personal best.
///
/// Tapping an entry pops the sheet returning that [ExerciseHistoryEntry];
/// the caller applies it to the set.
class ExerciseHistorySheet extends ConsumerStatefulWidget {
  const ExerciseHistorySheet({super.key, required this.exerciseName});

  final String exerciseName;

  @override
  ConsumerState<ExerciseHistorySheet> createState() =>
      _ExerciseHistorySheetState();
}

class _ExerciseHistorySheetState extends ConsumerState<ExerciseHistorySheet> {
  bool _loading = true;
  bool _showMax = false;
  List<ExerciseHistoryEntry> _recent = const [];
  List<ExerciseHistoryEntry> _top = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final active = ref.read(activeWorkoutProvider).valueOrNull;
    final sessionId = active?.sessionId ?? -1;
    final repo = ref.read(workoutRepositoryProvider);
    final recent = await repo.getExerciseHistory(widget.exerciseName, sessionId);
    final top = await repo.getTopSets(widget.exerciseName, sessionId);
    if (!mounted) return;
    setState(() {
      _recent = recent;
      _top = top;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entries = _showMax ? _top : _recent;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              widget.exerciseName,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Recent | Max toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Recent')),
                ButtonSegment(value: true, label: Text('Max')),
              ],
              selected: {_showMax},
              onSelectionChanged: (s) =>
                  setState(() => _showMax = s.first),
            ),
            const SizedBox(height: 8),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No history yet for this exercise',
                    style: TextStyle(color: cs.onSurface.withAlpha(140)),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) =>
                      _HistoryTile(entry: entries[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});
  final ExerciseHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateLabel = DateFormat('EEE, d MMM').format(entry.date);

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Text(
            _setLabel(entry),
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15),
          ),
          if (entry.isPr) ...[
            const SizedBox(width: 6),
            const Text('🏆', style: TextStyle(fontSize: 13)),
          ],
        ],
      ),
      subtitle: Text(dateLabel,
          style: TextStyle(
              fontSize: 12, color: cs.onSurface.withAlpha(140))),
      trailing: Icon(Icons.north_west_rounded,
          size: 18, color: cs.primary),
      onTap: () => Navigator.of(context).pop(entry),
    );
  }

  static String _setLabel(ExerciseHistoryEntry e) {
    final w = e.weightKg;
    final wStr = w == null
        ? '–'
        : (w == w.truncateToDouble() ? '${w.toInt()}' : '$w');
    final r = e.reps?.toString() ?? '–';
    return '$wStr kg × $r';
  }
}
