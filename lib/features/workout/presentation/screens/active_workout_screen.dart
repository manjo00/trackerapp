import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/program_exercise_model.dart';
import '../../data/models/workout_set_model.dart';
import '../providers/workout_providers.dart';
import '../widgets/exercise_accordion_card.dart';
import '../widgets/rest_timer_bar.dart';

/// The in-progress workout screen.
///
/// When started from a program session type:
///   • Exercise list is pre-loaded from the program (in order)
///   • Target sets × reps shown as a subtitle per exercise
///   • Last session's weight/reps are pre-filled into new sets
///   • Per-exercise rest time is used for the rest timer
///
/// When started as a freeform session:
///   • Blank slate — add exercises freely
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState
    extends ConsumerState<ActiveWorkoutScreen> {
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  DateTime? _startedAt;

  /// Exercise names whose cards are currently expanded.
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startedAt != null && mounted) {
        setState(() => _elapsed = DateTime.now().difference(_startedAt!));
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ── Finish ────────────────────────────────────────────────────────────────

  Future<void> _showFinishDialog() async {
    final active = ref.read(activeWorkoutProvider).valueOrNull;
    final nameCtrl = TextEditingController(
      text: active?.programSessionName ?? '',
    );
    final notesCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish Workout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Workout name (optional)',
                hintText: 'e.g. Push Day A',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save & Finish'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(activeWorkoutProvider.notifier).finish(
            name: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
            notes: notesCtrl.text.trim().isEmpty
                ? null
                : notesCtrl.text.trim(),
          );
      if (mounted) context.pop();
    }
  }

  Future<void> _showDiscardDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Workout?'),
        content: const Text(
            'Session stays in history as unnamed. You can keep going too.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      ref.read(activeWorkoutProvider.notifier).discard();
      context.pop();
    }
  }

  // ── Exercise management ───────────────────────────────────────────────────

  Future<void> _addExercise() async {
    final result =
        await context.push<ExerciseModel>('/workout/exercises');
    if (result == null || !mounted) return;
    // Auto-expand the new exercise and seed one empty set ("pop-up appears").
    setState(() => _expanded.add(result.name));
    await ref
        .read(activeWorkoutProvider.notifier)
        .ensureTargetSets(result.name, 1);
  }

  // ── Expand / collapse ─────────────────────────────────────────────────────

  Future<void> _toggleExpand(
      String name, ProgramExerciseModel? programEx) async {
    final willExpand = !_expanded.contains(name);
    setState(() {
      if (willExpand) {
        _expanded.add(name);
      } else {
        _expanded.remove(name);
      }
    });
    if (willExpand) {
      // Opening an exercise materialises its target sets (pre-filled prev hints).
      await ref
          .read(activeWorkoutProvider.notifier)
          .ensureTargetSets(name, programEx?.targetSets ?? 1);
    }
  }

  // ── Set complete → rest timer ─────────────────────────────────────────────

  void _onSetComplete(
      WorkoutSetModel set, ProgramExerciseModel? programEx) {
    final nowDone =
        ref.read(activeWorkoutProvider.notifier).toggleSetComplete(set.id);
    if (nowDone) {
      // Starting the universal rest timer; the top RestTimerBar reacts.
      final restSec = programEx?.restSeconds ?? 120;
      ref.read(restTimerProvider.notifier).start(restSec);
    }
  }

  Future<void> _deleteSet(int setId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Set?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(activeWorkoutProvider.notifier).deleteSet(setId);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(activeWorkoutProvider);

    return activeAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Workout')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (active) {
        if (active == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pop();
          });
          return const SizedBox.shrink();
        }
        _startedAt ??= active.startedAt;

        final exercises = active.exerciseNames;
        final setsByExercise = active.setsByExercise;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            title: Text(formatElapsed(_elapsed)),
            actions: [
              IconButton(
                icon: const Icon(Icons.timer_outlined),
                tooltip: 'Start / restart rest',
                onPressed: () =>
                    ref.read(restTimerProvider.notifier).reinitiate(),
              ),
              TextButton(
                onPressed: _showFinishDialog,
                child: const Text('Finish',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              PopupMenuButton<String>(
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'discard',
                      child: Text('Discard Workout')),
                ],
                onSelected: (v) {
                  if (v == 'discard') _showDiscardDialog();
                },
              ),
            ],
          ),
          body: Column(
            children: [
              const RestTimerBar(),
              Expanded(
                child: exercises.isEmpty
                    ? _NoExercisesPlaceholder(onAdd: _addExercise)
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: exercises.length,
                        itemBuilder: (ctx, i) {
                          final name = exercises[i];
                          final sets = setsByExercise[name] ?? [];
                          final programEx =
                              active.programExerciseFor(name);
                          return ExerciseAccordionCard(
                            exerciseName: name,
                            sets: sets,
                            programExercise: programEx,
                            completedSetIds: active.completedSetIds,
                            expanded: _expanded.contains(name),
                            onToggleExpand: () =>
                                _toggleExpand(name, programEx),
                            onUpdateSet: (updated) => ref
                                .read(activeWorkoutProvider.notifier)
                                .updateSet(updated),
                            onCompleteSet: (set) =>
                                _onSetComplete(set, programEx),
                            onDeleteSet: _deleteSet,
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
      },
    );
  }
}

class _NoExercisesPlaceholder extends StatelessWidget {
  const _NoExercisesPlaceholder({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fitness_center_rounded,
              size: 64, color: cs.onSurface.withAlpha(60)),
          const SizedBox(height: 16),
          Text('No exercises yet',
              style: TextStyle(color: cs.onSurface.withAlpha(140))),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add First Exercise'),
          ),
        ],
      ),
    );
  }
}
