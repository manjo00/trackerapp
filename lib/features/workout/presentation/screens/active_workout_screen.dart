import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/workout_set_model.dart';
import '../providers/workout_providers.dart';
import '../widgets/rest_timer_bottom_sheet.dart';
import '../widgets/set_row.dart';

/// The in-progress workout screen.
///
/// What it provides:
///   • AppBar with a live elapsed-time counter and a "Finish" button
///   • A section per exercise (with set rows)
///   • "Add Set" button per exercise
///   • "Add Exercise" FAB → navigates to ExercisePickerScreen
///   • Tapping ✓ on a set saves it and opens RestTimerBottomSheet
///   • Long-press a set → delete
///   • "Discard Workout" in the overflow menu
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState
    extends ConsumerState<ActiveWorkoutScreen> {
  // ── Elapsed timer ─────────────────────────────────────────────────────────
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startedAt != null && mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(_startedAt!);
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ── Finish dialog ─────────────────────────────────────────────────────────

  Future<void> _showFinishDialog() async {
    final nameCtrl = TextEditingController();
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
                hintText: 'e.g. Push day',
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
            notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
          );
      if (mounted) context.pop();
    }
  }

  // ── Discard dialog ────────────────────────────────────────────────────────

  Future<void> _showDiscardDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Workout?'),
        content: const Text(
          'The session will remain in history as an unnamed entry. '
          'You can also go back and keep logging.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
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

  // ── Add exercise ──────────────────────────────────────────────────────────

  Future<void> _addExercise() async {
    final result =
        await context.push<ExerciseModel>('/workout/exercises');
    if (result == null) return;
    // Add first set for the new exercise right away.
    if (mounted) {
      await ref.read(activeWorkoutProvider.notifier).addSet(
            exerciseName: result.name,
            exerciseId: result.id,
          );
    }
  }

  // ── Set actions ───────────────────────────────────────────────────────────

  void _onSetComplete(WorkoutSetModel set) {
    // Start rest timer and show bottom sheet.
    ref.read(restTimerProvider.notifier).start(90);
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => const RestTimerBottomSheet(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
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
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
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
          // Session finished or not started — go back.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.pop();
          });
          return const SizedBox.shrink();
        }

        // Sync elapsed clock when screen is first rendered.
        _startedAt ??= active.startedAt;

        final exercises = active.exerciseNames;
        final setsByExercise = active.setsByExercise;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
              tooltip: 'Back',
            ),
            title: Text(formatElapsed(_elapsed)),
            actions: [
              TextButton(
                onPressed: _showFinishDialog,
                child: const Text(
                  'Finish',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              PopupMenuButton<String>(
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'discard',
                    child: Text('Discard Workout'),
                  ),
                ],
                onSelected: (v) {
                  if (v == 'discard') _showDiscardDialog();
                },
              ),
            ],
          ),

          body: exercises.isEmpty
              ? _NoExercisesPlaceholder(onAdd: _addExercise)
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: exercises.length,
                  itemBuilder: (context, i) {
                    final name = exercises[i];
                    final sets = setsByExercise[name] ?? [];
                    return _ExerciseSection(
                      exerciseName: name,
                      sets: sets,
                      sessionId: active.sessionId,
                      onAddSet: () async {
                        await ref
                            .read(activeWorkoutProvider.notifier)
                            .addSet(exerciseName: name);
                      },
                      onUpdateSet: (updated) => ref
                          .read(activeWorkoutProvider.notifier)
                          .updateSet(updated),
                      onCompleteSet: _onSetComplete,
                      onDeleteSet: _deleteSet,
                    );
                  },
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

// ── Exercise section ──────────────────────────────────────────────────────────

/// A card-like section grouping all sets for one exercise.
class _ExerciseSection extends ConsumerWidget {
  const _ExerciseSection({
    required this.exerciseName,
    required this.sets,
    required this.sessionId,
    required this.onAddSet,
    required this.onUpdateSet,
    required this.onCompleteSet,
    required this.onDeleteSet,
  });

  final String exerciseName;
  final List<WorkoutSetModel> sets;
  final int sessionId;
  final VoidCallback onAddSet;
  final ValueChanged<WorkoutSetModel> onUpdateSet;
  final ValueChanged<WorkoutSetModel> onCompleteSet;
  final ValueChanged<int> onDeleteSet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load last-session hints for this exercise.
    final hintsAsync =
        ref.watch(lastSessionHintsProvider(exerciseName));
    final hints = hintsAsync.valueOrNull ?? const [];

    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise header
            Row(
              children: [
                Expanded(
                  child: Text(
                    exerciseName,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (hints.isNotEmpty)
                  Tooltip(
                    message: 'Previous session data shown as hints',
                    child: Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: cs.onSurface.withAlpha(120),
                    ),
                  ),
              ],
            ),

            // Column headers
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const SizedBox(width: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Weight',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withAlpha(140),
                          ),
                    ),
                  ),
                  const SizedBox(width: 28), // ×
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Reps',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withAlpha(140),
                          ),
                    ),
                  ),
                  const SizedBox(width: 44), // ✓ button
                ],
              ),
            ),

            const Divider(height: 1),

            // Set rows
            ...sets.asMap().entries.map((e) {
              final index = e.key;
              final set = e.value;
              // Match hint by position (same set number from last session).
              final WorkoutSetModel? hint =
                  index < hints.length ? hints[index] : null;

              return SetRow(
                key: ValueKey(set.id),
                set: set,
                hint: hint,
                onUpdate: onUpdateSet,
                onComplete: () => onCompleteSet(set),
                onDelete: () => onDeleteSet(set.id),
              );
            }),

            const SizedBox(height: 8),

            // Add Set button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddSet,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Set'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(
                      color: cs.outline.withAlpha(80)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── No-exercises placeholder ──────────────────────────────────────────────────

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
          Icon(
            Icons.fitness_center_rounded,
            size: 64,
            color: cs.onSurface.withAlpha(60),
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.onSurface.withAlpha(140),
                ),
          ),
          const SizedBox(height: 8),
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
