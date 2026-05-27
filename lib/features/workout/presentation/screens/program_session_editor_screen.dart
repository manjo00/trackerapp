import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/program_exercise_model.dart';
import '../../data/models/program_model.dart';
import '../../data/models/program_session_model.dart';
import '../providers/program_providers.dart';
import '../providers/workout_providers.dart';

/// Edit the exercises inside one session type.
///
/// Features:
///   • Reorder exercises via drag handles
///   • Edit target sets / reps / rest per exercise
///   • Add exercises via the Exercise Picker
///   • "Start Workout" button in the app bar to log a session immediately
///   • Delete exercises
class ProgramSessionEditorScreen extends ConsumerWidget {
  const ProgramSessionEditorScreen({
    super.key,
    required this.programId,
    required this.sessionId,
  });

  final int programId;
  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(allProgramsProvider);

    return programsAsync.when(
      loading: () => Scaffold(
          appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (programs) {
        final program = programs.where((p) => p.id == programId).firstOrNull;
        final session = program?.sessions
            .where((s) => s.id == sessionId)
            .firstOrNull;

        if (program == null || session == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Session')),
            body: const Center(child: Text('Session not found')),
          );
        }

        return _SessionEditorView(program: program, session: session);
      },
    );
  }
}

class _SessionEditorView extends ConsumerStatefulWidget {
  const _SessionEditorView({
    required this.program,
    required this.session,
  });

  final ProgramModel program;
  final ProgramSessionModel session;

  @override
  ConsumerState<_SessionEditorView> createState() =>
      _SessionEditorViewState();
}

class _SessionEditorViewState
    extends ConsumerState<_SessionEditorView> {
  ProgramSessionModel get session => widget.session;

  // ── Start workout ────────────────────────────────────────────────────────

  Future<void> _startWorkout() async {
    // If a workout is already in progress, just resume it.
    final existing = ref.read(activeWorkoutProvider).valueOrNull;
    if (existing != null) {
      context.push('/workout/active');
      return;
    }
    await ref.read(activeWorkoutProvider.notifier).start(
          programSessionId: session.id,
          programExercises: session.exercises,
          programSessionName: session.name,
        );
    if (mounted) context.push('/workout/active');
  }

  // ── Add exercise ────────────────────────────────────────────────────────

  Future<void> _addExercise() async {
    final result =
        await context.push<ExerciseModel>('/workout/exercises');
    if (result == null || !mounted) return;

    final repo = ref.read(programRepositoryProvider);
    final orderIndex = session.exercises.length;
    await repo.addExercise(
      programSessionId: session.id,
      exerciseId: result.id,
      exerciseName: result.name,
      orderIndex: orderIndex,
    );
  }

  // ── Edit exercise ────────────────────────────────────────────────────────

  Future<void> _editExercise(ProgramExerciseModel ex) async {
    final result =
        await showDialog<ProgramExerciseModel>(
      context: context,
      builder: (_) => _ExerciseEditDialog(exercise: ex),
    );
    if (result != null) {
      await ref.read(programRepositoryProvider).updateExercise(result);
    }
  }

  // ── Delete exercise ──────────────────────────────────────────────────────

  Future<void> _deleteExercise(ProgramExerciseModel ex) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove "${ex.exerciseName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(programRepositoryProvider)
          .deleteExercise(ex.id);
    }
  }

  // ── Reorder ─────────────────────────────────────────────────────────────

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    // onReorderItem already provides the adjusted newIndex
    final exercises = [...session.exercises];
    final moved = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, moved);

    final repo = ref.read(programRepositoryProvider);
    for (int i = 0; i < exercises.length; i++) {
      await repo.updateExercise(
          exercises[i].copyWith(orderIndex: i));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final exercises = session.exercises;
    final color = session.color;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(session.name),
          ],
        ),
        actions: [
          if (widget.program.isWeekly &&
              session.weekDayLabel.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(label: Text(session.weekDayLabel)),
            ),
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded),
            tooltip: 'Start workout',
            color: Theme.of(context).colorScheme.primary,
            onPressed: _startWorkout,
          ),
        ],
      ),

      body: exercises.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fitness_center_rounded,
                      size: 48, color: cs.onSurface.withAlpha(60)),
                  const SizedBox(height: 12),
                  Text('No exercises yet',
                      style: TextStyle(color: cs.onSurface.withAlpha(140))),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Exercise'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Icon(Icons.drag_indicator_rounded,
                          size: 16,
                          color: cs.onSurface.withAlpha(100)),
                      const SizedBox(width: 4),
                      Text(
                        'Drag to reorder  •  Tap to edit',
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withAlpha(120)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: exercises.length,
                    onReorderItem: _onReorder,
                    itemBuilder: (ctx, i) {
                      final ex = exercises[i];
                      return _ExerciseTile(
                        key: ValueKey(ex.id),
                        exercise: ex,
                        color: color,
                        onEdit: () => _editExercise(ex),
                        onDelete: () => _deleteExercise(ex),
                      );
                    },
                  ),
                ),
              ],
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExercise,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Exercise'),
      ),
    );
  }
}

// ── Exercise tile ─────────────────────────────────────────────────────────────

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    super.key,
    required this.exercise,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  final ProgramExerciseModel exercise;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.drag_indicator_rounded,
          color: cs.onSurface.withAlpha(80)),
      title: Text(exercise.exerciseName,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${exercise.volumeLabel}  •  Rest ${exercise.restLabel}',
        style:
            TextStyle(fontSize: 12, color: cs.onSurface.withAlpha(160)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            iconSize: 20,
            color: cs.primary,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            iconSize: 20,
            color: cs.onSurface.withAlpha(120),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ── Exercise edit dialog ──────────────────────────────────────────────────────

class _ExerciseEditDialog extends StatefulWidget {
  const _ExerciseEditDialog({required this.exercise});
  final ProgramExerciseModel exercise;

  @override
  State<_ExerciseEditDialog> createState() =>
      _ExerciseEditDialogState();
}

class _ExerciseEditDialogState extends State<_ExerciseEditDialog> {
  late int sets;
  late int reps;
  late int restSeconds;

  // Preset rest options in seconds
  static const List<int> _restPresets = [
    30, 60, 90, 120, 150, 180, 210, 240, 300,
  ];

  @override
  void initState() {
    super.initState();
    sets = widget.exercise.targetSets;
    reps = widget.exercise.targetReps;
    restSeconds = widget.exercise.restSeconds;
  }

  String _restLabel(int s) {
    final m = s ~/ 60;
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.exercise.exerciseName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sets
          Row(
            children: [
              const Expanded(child: Text('Target sets')),
              _Stepper(
                value: sets,
                min: 1,
                max: 10,
                onChanged: (v) => setState(() => sets = v),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Reps
          Row(
            children: [
              const Expanded(child: Text('Target reps')),
              _Stepper(
                value: reps,
                min: 1,
                max: 50,
                onChanged: (v) => setState(() => reps = v),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rest time
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Rest between sets',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _restPresets.map((s) {
              final sel = restSeconds == s;
              return GestureDetector(
                onTap: () => setState(() => restSeconds = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _restLabel(s),
                    style: TextStyle(
                      color: sel
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            widget.exercise.copyWith(
              targetSets: sets,
              targetReps: reps,
              restSeconds: restSeconds,
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_rounded),
          iconSize: 20,
          onPressed:
              value > min ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_rounded),
          iconSize: 20,
          onPressed:
              value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
