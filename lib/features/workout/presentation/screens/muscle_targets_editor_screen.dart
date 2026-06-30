import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../data/models/muscle_groups.dart';
import '../providers/workout_providers.dart';

/// Edit the weekly goal for each muscle: how many sessions (frequency) and how
/// many sets per session. Weekly set target = frequency × sets/session.
class MuscleTargetsEditorScreen extends ConsumerWidget {
  const MuscleTargetsEditorScreen({super.key});

  static const int _maxFreq = 7;
  static const int _maxSets = 12;

  void _save(WidgetRef ref, MuscleTarget t, {int? freq, int? sets}) {
    ref.read(workoutRepositoryProvider).updateMuscleTarget(
          MuscleTargetsCompanion(
            id: Value(t.id),
            frequency: freq != null ? Value(freq) : const Value.absent(),
            setsPerSession: sets != null ? Value(sets) : const Value.absent(),
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<MuscleTarget> targets =
        ref.watch(weeklyTargetsProvider).valueOrNull ?? const [];
    final Map<String, MuscleTarget> byKey = {
      for (final MuscleTarget t in targets) t.groupKey: t,
    };

    final List<Widget> rows = [];
    String? lastGroup;
    for (final String muscle in MuscleGroup.trackedMuscles) {
      final MuscleTarget? t = byKey[muscle];
      if (t == null) continue;
      final String group = MuscleGroup.forMuscle(muscle) ?? MuscleGroup.core;
      if (group != lastGroup) {
        rows.add(_Header(label: MuscleGroup.label(group)));
        lastGroup = group;
      }
      rows.add(_TargetRow(
        muscle: muscle,
        frequency: t.frequency,
        setsPerSession: t.setsPerSession,
        onFreq: (v) => _save(ref, t, freq: v.clamp(0, _maxFreq)),
        onSets: (v) => _save(ref, t, sets: v.clamp(1, _maxSets)),
      ));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly goals')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Set how often and how many sets you want each muscle per week. '
              'Weekly sets = frequency × sets/session.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
                    height: 1.5,
                  ),
            ),
          ),
          ...rows,
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: cs.primary,
        ),
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  const _TargetRow({
    required this.muscle,
    required this.frequency,
    required this.setsPerSession,
    required this.onFreq,
    required this.onSets,
  });

  final String muscle;
  final int frequency;
  final int setsPerSession;
  final ValueChanged<int> onFreq;
  final ValueChanged<int> onSets;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(muscle,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                Text(
                  '$frequency× · ${frequency * setsPerSession} sets/wk',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurface.withAlpha(150)),
                ),
              ],
            ),
          ),
          _Stepper(label: 'freq', value: frequency, onChanged: onFreq),
          const SizedBox(width: 12),
          _Stepper(label: 'sets', value: setsPerSession, onChanged: onSets),
        ],
      ),
    );
  }
}

/// A small "− N +" stepper with a caption.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 10, color: cs.onSurface.withAlpha(130))),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _btn(Icons.remove_rounded, () => onChanged(value - 1), cs),
            SizedBox(
              width: 26,
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            _btn(Icons.add_rounded, () => onChanged(value + 1), cs),
          ],
        ),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap, ColorScheme cs) {
    return InkResponse(
      onTap: onTap,
      radius: 20,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cs.primary.withAlpha(28),
        ),
        child: Icon(icon, size: 18, color: cs.primary),
      ),
    );
  }
}
