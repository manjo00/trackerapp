import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// View mode: group cards by muscle vs. manual (program) order.
  bool _byMuscle = false;

  /// exercise name → primary muscle (loaded once from the library).
  Map<String, String> _muscleByName = const {};

  /// shared_preferences key for this session type's view mode.
  String _viewPrefKey = 'workout_view_freeform';

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startedAt != null && mounted) {
        setState(() => _elapsed = DateTime.now().difference(_startedAt!));
      }
    });
    _loadViewPrefs();
  }

  /// Loads the name→muscle map and the persisted view mode for this session.
  Future<void> _loadViewPrefs() async {
    final repo = ref.read(workoutRepositoryProvider);
    final all = await repo.getAllExercises();
    final prefs = await SharedPreferences.getInstance();
    final sid = ref.read(activeWorkoutProvider).valueOrNull?.programSessionId;
    final key = 'workout_view_${sid ?? 'freeform'}';
    if (!mounted) return;
    setState(() {
      _muscleByName = {for (final e in all) e.name: e.primaryMuscle};
      _viewPrefKey = key;
      _byMuscle = prefs.getBool(key) ?? false;
    });
  }

  Future<void> _setByMuscle(bool value) async {
    setState(() => _byMuscle = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_viewPrefKey, value);
  }

  /// Builds the display list: exercises in program order, or grouped under
  /// muscle headers when [_byMuscle] is on.
  List<_DisplayItem> _buildItems(List<String> exercises) {
    if (!_byMuscle) {
      return exercises.map(_DisplayItem.exercise).toList();
    }
    final groups = <String, List<String>>{};
    for (final name in exercises) {
      final muscle = _muscleByName[name] ?? 'Other';
      (groups[muscle] ??= []).add(name);
    }
    final muscles = groups.keys.toList()..sort();
    final items = <_DisplayItem>[];
    for (final m in muscles) {
      items.add(_DisplayItem.header(m));
      items.addAll(groups[m]!.map(_DisplayItem.exercise));
    }
    return items;
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
                  CheckedPopupMenuItem(
                    value: 'muscle',
                    checked: _byMuscle,
                    child: const Text('Group by muscle'),
                  ),
                  const PopupMenuItem(
                      value: 'discard',
                      child: Text('Discard Workout')),
                ],
                onSelected: (v) {
                  if (v == 'muscle') _setByMuscle(!_byMuscle);
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
                    : Builder(
                        builder: (ctx) {
                          final items = _buildItems(exercises);
                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 120),
                            itemCount: items.length,
                            itemBuilder: (ctx, i) {
                              final item = items[i];
                              if (item.muscleHeader != null) {
                                return _MuscleHeader(
                                    label: item.muscleHeader!);
                              }
                              final name = item.exerciseName!;
                              final sets = setsByExercise[name] ?? [];
                              final programEx =
                                  active.programExerciseFor(name);
                              return ExerciseAccordionCard(
                                exerciseName: name,
                                sets: sets,
                                programExercise: programEx,
                                completedSetIds: active.completedSetIds,
                                expanded: _expanded.contains(name),
                                muscle: _muscleByName[name],
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

/// One row in the active-day list: either a muscle-group header or an exercise.
class _DisplayItem {
  const _DisplayItem._({this.muscleHeader, this.exerciseName});
  const _DisplayItem.header(String muscle) : this._(muscleHeader: muscle);
  const _DisplayItem.exercise(String name) : this._(exerciseName: name);

  final String? muscleHeader;
  final String? exerciseName;
}

class _MuscleHeader extends StatelessWidget {
  const _MuscleHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: cs.primary,
        ),
      ),
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
