import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/muscle_group.dart';
import '../providers/workout_providers.dart';

/// Full-screen exercise picker.
///
/// The user can:
///   • Search by name (live filtering via [exerciseFilterProvider])
///   • Filter by muscle group (horizontal chip row)
///   • Add a custom exercise via a bottom sheet dialog
///   • Tap any exercise to pop back with the selected [ExerciseModel]
///
/// Call this screen via go_router and receive the result:
/// ```dart
/// final result = await context.push<ExerciseModel>('/workout/exercises');
/// ```
class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  ConsumerState<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState
    extends ConsumerState<ExercisePickerScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    // Reset filter so next open starts fresh.
    ref.read(exerciseFilterProvider.notifier).reset();
    super.dispose();
  }

  void _pick(ExerciseModel exercise) {
    context.pop(exercise);
  }

  void _showAddCustomDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddCustomExerciseSheet(
        onCreated: _pick,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(exerciseFilterProvider);
    final exercisesAsync = ref.watch(filteredExercisesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Exercise'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Search exercises…',
              leading: const Icon(Icons.search_rounded),
              trailing: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchCtrl.clear();
                      ref
                          .read(exerciseFilterProvider.notifier)
                          .setQuery('');
                    },
                  ),
              ],
              onChanged: (q) =>
                  ref.read(exerciseFilterProvider.notifier).setQuery(q),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // ── Muscle group chip filter ──────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final group in MuscleGroup.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(group.label),
                      selected: filter.muscle ==
                          (group == MuscleGroup.all ? null : group.name),
                      onSelected: (_) {
                        final newMuscle = group == MuscleGroup.all
                            ? null
                            : group.name;
                        ref
                            .read(exerciseFilterProvider.notifier)
                            .setMuscle(newMuscle);
                      },
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Exercise list ─────────────────────────────────────────────
          Expanded(
            child: exercisesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48,
                            color: cs.onSurface.withAlpha(80)),
                        const SizedBox(height: 12),
                        Text(
                          'No exercises found',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: cs.onSurface.withAlpha(140),
                                  ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, i) =>
                      _ExerciseTile(
                    exercise: exercises[i],
                    onTap: () => _pick(exercises[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ── Add custom exercise ───────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: _showAddCustomDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add custom exercise'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Exercise tile ─────────────────────────────────────────────────────────────

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise, required this.onTap});

  final ExerciseModel exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      title: Text(exercise.name),
      subtitle: Text(
        exercise.primaryMuscle,
        style: TextStyle(color: cs.onSurface.withAlpha(160)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SmallChip(label: exercise.equipment),
          if (exercise.isCustom) ...[
            const SizedBox(width: 6),
            const _SmallChip(label: 'Custom', isPrimary: true),
          ],
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({required this.label, this.isPrimary = false});

  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPrimary
            ? cs.primaryContainer
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isPrimary ? cs.onPrimaryContainer : cs.onSurface,
            ),
      ),
    );
  }
}

// ── Add custom exercise bottom sheet ─────────────────────────────────────────

class _AddCustomExerciseSheet extends ConsumerStatefulWidget {
  const _AddCustomExerciseSheet({required this.onCreated});

  final ValueChanged<ExerciseModel> onCreated;

  @override
  ConsumerState<_AddCustomExerciseSheet> createState() =>
      _AddCustomExerciseSheetState();
}

class _AddCustomExerciseSheetState
    extends ConsumerState<_AddCustomExerciseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String _muscle = 'Chest';
  String _equipment = 'Barbell';
  bool _saving = false;

  static const List<String> _muscles = [
    'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core', 'Glutes', 'Other',
  ];
  static const List<String> _equipments = [
    'Barbell', 'Dumbbell', 'Machine', 'Cable', 'Bodyweight',
    'Kettlebell', 'Bands', 'Smith Machine', 'Other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(workoutRepositoryProvider);
      final exercise = await repo.addCustomExercise(
        name: _nameCtrl.text.trim(),
        primaryMuscle: _muscle,
        equipment: _equipment,
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCreated(exercise);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Custom Exercise',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Exercise name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name required' : null,
            ),
            const SizedBox(height: 12),

            _LabeledDropdown<String>(
              label: 'Primary Muscle',
              value: _muscle,
              items: _muscles,
              onChanged: (v) => setState(() => _muscle = v!),
            ),
            const SizedBox(height: 12),

            _LabeledDropdown<String>(
              label: 'Equipment',
              value: _equipment,
              items: _equipments,
              onChanged: (v) => setState(() => _equipment = v!),
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Exercise'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      // ignore: deprecated_member_use
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text('$item'),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
