import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/program_exercise_model.dart';
import '../../data/models/workout_set_model.dart';
import '../providers/workout_providers.dart';
import 'set_row.dart';

/// A collapsible exercise card on the active-workout screen.
///
/// - **Collapsed:** name, optional muscle chip, progress (`2/3 sets`, top set),
///   and a green check when every target set is done.
/// - **Expanded:** the set table ([SetRow]s) + "Add Set".
///
/// Collapsing never ends the exercise — all set + completion state lives in the
/// [ActiveWorkout] provider, so the user can minimise one exercise, do another,
/// and come back with everything intact (e.g. to rest a muscle).
class ExerciseAccordionCard extends ConsumerWidget {
  const ExerciseAccordionCard({
    super.key,
    required this.exerciseName,
    required this.sets,
    required this.programExercise,
    required this.completedSetIds,
    required this.expanded,
    required this.onToggleExpand,
    required this.onCompleteSet,
    required this.onUpdateSet,
    required this.onDeleteSet,
    this.muscle,
  });

  final String exerciseName;
  final List<WorkoutSetModel> sets;
  final ProgramExerciseModel? programExercise;
  final Set<int> completedSetIds;
  final bool expanded;
  final String? muscle;
  final VoidCallback onToggleExpand;
  final ValueChanged<WorkoutSetModel> onCompleteSet;
  final ValueChanged<WorkoutSetModel> onUpdateSet;
  final ValueChanged<int> onDeleteSet;

  int get _targetCount =>
      programExercise?.targetSets ?? (sets.isEmpty ? 1 : sets.length);

  int get _completedCount =>
      sets.where((s) => completedSetIds.contains(s.id)).length;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final hints =
        ref.watch(lastSessionHintsProvider(exerciseName)).valueOrNull ??
            const [];

    final completed = _completedCount;
    final target = _targetCount;
    final allDone = target > 0 && completed >= target;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (tap to expand/collapse) ───────────────────────────────
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  // Done indicator / progress dot
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: allDone
                          ? Colors.green
                          : cs.surfaceContainerHighest,
                    ),
                    child: allDone
                        ? const Icon(Icons.check_rounded,
                            size: 16, color: Colors.white)
                        : Center(
                            child: Text(
                              '$completed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface.withAlpha(180),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                exerciseName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (muscle != null) ...[
                              const SizedBox(width: 8),
                              _MuscleChip(muscle: muscle!),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _summary(),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withAlpha(150),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: cs.onSurface.withAlpha(150),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded body ─────────────────────────────────────────────────
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Column(
                children: [
                  ...sets.asMap().entries.map((e) {
                    final index = e.key;
                    final set = e.value;
                    final hint = index < hints.length ? hints[index] : null;
                    return SetRow(
                      key: ValueKey(set.id),
                      set: set,
                      hint: hint,
                      isCompleted: completedSetIds.contains(set.id),
                      onUpdate: onUpdateSet,
                      onComplete: () => onCompleteSet(set),
                      onDelete: () => onDeleteSet(set.id),
                    );
                  }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _addSet(ref, hints),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add Set'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(color: cs.outline.withAlpha(80)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Collapsed summary line: "2/3 sets · top 60 × 8" or "Target 3 × 10".
  String _summary() {
    final completed = _completedCount;
    final target = _targetCount;

    // Heaviest completed set, if any.
    WorkoutSetModel? top;
    for (final s in sets) {
      if (!completedSetIds.contains(s.id) || s.weightKg == null) continue;
      if (top == null || (s.weightKg ?? 0) > (top.weightKg ?? 0)) top = s;
    }

    final parts = <String>['$completed/$target sets'];
    if (top != null) {
      parts.add('top ${_fmt(top.weightKg)} × ${top.reps ?? '–'}');
    } else if (programExercise != null) {
      parts.add('target ${programExercise!.volumeLabel}');
    }
    return parts.join('  ·  ');
  }

  Future<void> _addSet(WidgetRef ref, List<WorkoutSetModel> hints) async {
    double? weight;
    int? reps;
    if (sets.isNotEmpty) {
      weight = sets.last.weightKg;
      reps = sets.last.reps;
    } else if (hints.isNotEmpty) {
      weight = hints.first.weightKg;
      reps = hints.first.reps;
    }
    await ref.read(activeWorkoutProvider.notifier).addSet(
          exerciseName: exerciseName,
          weightKg: weight,
          reps: reps,
        );
  }

  static String _fmt(double? kg) {
    if (kg == null) return '–';
    return kg == kg.truncateToDouble() ? '${kg.toInt()}' : '$kg';
  }
}

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({required this.muscle});
  final String muscle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        muscle,
        style: TextStyle(
          fontSize: 10,
          color: cs.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
