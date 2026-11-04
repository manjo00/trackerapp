import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/workout_session_model.dart';
import '../../data/models/workout_set_model.dart';
import '../../domain/workout_summary.dart';
import '../providers/workout_providers.dart';

/// One past workout (look B, Ahmed's pick 2026-11-04): the kilos lifted as the
/// headline and how they compare with the last workout of the same plan, then
/// every exercise in the order it was done, with each set and how its best set
/// changed since last time. Opened from a row of the history.
class WorkoutSessionScreen extends ConsumerWidget {
  const WorkoutSessionScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<WorkoutSessionModel>> history =
        ref.watch(allWorkoutSessionsProvider);
    final List<WorkoutSessionModel> sessions = history.valueOrNull ?? const [];
    final WorkoutSessionModel? session =
        sessions.where((s) => s.id == sessionId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(session?.displayName ?? 'Workout')),
      body: history.isLoading && session == null
          ? const Center(child: CircularProgressIndicator())
          : session == null
              ? const Center(
                  child: Text('This workout is no longer in your history.'))
              : _WorkoutPage(
                  session: session,
                  previous: previousOfSamePlan(sessions, session),
                ),
    );
  }
}

class _WorkoutPage extends StatelessWidget {
  const _WorkoutPage({required this.session, required this.previous});

  final WorkoutSessionModel session;
  final WorkoutSessionModel? previous;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color muted = theme.colorScheme.onSurface.withAlpha(150);
    final List<WorkoutSetModel> logged =
        session.sets.where(isLogged).toList();
    final double kg = kgLifted(logged);
    final int records = recordCount(logged);
    final WorkoutSessionModel? before = previous;
    final DateTime date = DateTime.tryParse(session.date) ?? session.createdAt;
    final String? length = lengthLabel(session);
    final List<String> order = exercisesInDoneOrder([
      for (final WorkoutSetModel s in logged)
        (name: s.exerciseName, tick: s.completedAt),
    ]);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Text(
          fullKg(kg),
          style: theme.textTheme.headlineMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          [
            'lifted',
            DateFormat('EEE, d MMM').format(date),
            'started ${DateFormat.Hm().format(session.createdAt)}',
            if (length != null) length,
          ].join(' · '),
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (before != null) _KgChange(session: session, before: before),
            Text(
              [
                '${logged.length} ${logged.length == 1 ? 'set' : 'sets'}',
                if (records > 0)
                  '$records ${records == 1 ? 'record' : 'records'}',
              ].join(' · '),
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final String name in order)
          _ExerciseBlock(
            sets: [
              for (final WorkoutSetModel s in logged)
                if (s.exerciseName == name) s,
            ],
            before: before == null
                ? null
                : [
                    for (final WorkoutSetModel s in before.sets)
                      if (s.exerciseName == name) s,
                  ],
          ),
      ],
    );
  }
}

/// "+635 kg vs last Push": the whole workout's kilos against [before].
class _KgChange extends StatelessWidget {
  const _KgChange({required this.session, required this.before});

  final WorkoutSessionModel session;
  final WorkoutSessionModel before;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double diff = kgLifted(session.sets) - kgLifted(before.sets);
    final String? name = session.name;
    final String last =
        'last ${name != null && name.isNotEmpty ? name : 'time'}';
    final String label = diff.round() == 0
        ? 'same kilos as $last'
        : '${diff > 0 ? '+' : '−'}${fullKg(diff.abs())} vs $last';
    final bool more = diff.round() > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: more
            ? _better(theme).withAlpha(40)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
            color: more ? _better(theme) : theme.colorScheme.onSurface),
      ),
    );
  }
}

/// One exercise: its name and first tick time, how its best set changed
/// since last time (when there is a last time), and every set.
class _ExerciseBlock extends StatelessWidget {
  const _ExerciseBlock({required this.sets, required this.before});

  /// This exercise's logged sets, in the order they were made.
  final List<WorkoutSetModel> sets;

  /// Its sets in the last workout of the plan; null when there was none.
  final List<WorkoutSetModel>? before;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Color muted = cs.onSurface.withAlpha(150);
    final List<WorkoutSetModel>? last = before;
    final ({String label, bool better})? change = last == null
        ? null
        : changeSinceLastTime(topSet(sets), topSet(last));
    final DateTime? tick = [
      for (final WorkoutSetModel s in sets)
        if (s.completedAt case final DateTime t) t,
    ].fold<DateTime?>(null, (a, t) => a == null || t.isBefore(a) ? t : a);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outlineVariant, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        sets.first.exerciseName,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (tick != null) ...[
                      const SizedBox(width: 8),
                      Text(DateFormat.Hm().format(tick),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: muted)),
                    ],
                  ],
                ),
              ),
              if (change != null) ...[
                const SizedBox(width: 8),
                Text(
                  change.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: change.better ? _better(theme) : muted),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final WorkoutSetModel s in sets) _SetChip(set: s),
            ],
          ),
        ],
      ),
    );
  }
}

/// One set: "80 × 8", with a trophy when it was a record; warm-ups are
/// marked "W" and quieter.
class _SetChip extends StatelessWidget {
  const _SetChip({required this.set});

  final WorkoutSetModel set;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest
            .withAlpha(set.isWarmup ? 110 : 255),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (set.isWarmup)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text('W',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: cs.onSurface.withAlpha(150))),
            ),
          Text(setLabel(set), style: theme.textTheme.labelMedium),
          if (set.isPr) ...[
            const SizedBox(width: 4),
            Icon(Icons.emoji_events_rounded, size: 14, color: Colors.amber.shade600),
          ],
        ],
      ),
    );
  }
}

/// The green of "more than last time", readable in both themes.
Color _better(ThemeData theme) => theme.brightness == Brightness.dark
    ? Colors.green.shade300
    : Colors.green.shade700;
