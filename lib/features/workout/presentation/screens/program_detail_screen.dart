import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/program_exercise_model.dart';
import '../../data/models/program_model.dart';
import '../../data/models/program_session_model.dart';
import '../providers/program_providers.dart';
import '../providers/workout_providers.dart';

/// Shows all session types in a program with their exercises.
///
/// Allows:
///   • Renaming the program
///   • Setting as active
///   • Adding session types (FAB)
///   • Tapping a session → session editor
///   • Deleting the program
class ProgramDetailScreen extends ConsumerWidget {
  const ProgramDetailScreen({super.key, required this.programId});

  final int programId;

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
        if (program == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Program')),
            body: const Center(child: Text('Program not found')),
          );
        }
        return _ProgramDetailView(program: program);
      },
    );
  }
}

class _ProgramDetailView extends ConsumerStatefulWidget {
  const _ProgramDetailView({required this.program});
  final ProgramModel program;

  @override
  ConsumerState<_ProgramDetailView> createState() =>
      _ProgramDetailViewState();
}

class _ProgramDetailViewState
    extends ConsumerState<_ProgramDetailView> {
  ProgramModel get program => widget.program;

  Future<void> _startSession(ProgramSessionModel session) async {
    final existing = ref.read(activeWorkoutProvider).valueOrNull;
    if (existing != null) {
      context.push('/workout/active');
      return;
    }
    await ref.read(activeWorkoutProvider.notifier).start(
          programSessionId: session.id,
          programExercises: session.exercises,
        );
    if (mounted) context.push('/workout/active');
  }

  Future<void> _addSession() async {
    final nameCtrl = TextEditingController();
    int colorValue = 0xFF6750A4;
    String? weekDays;
    final colorOptions = [
      0xFFE53935, 0xFF1E88E5, 0xFF43A047,
      0xFF8E24AA, 0xFFF57C00, 0xFF00ACC1,
    ];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Session Type'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Session name',
                    hintText: 'e.g. Push, Pull, Legs, Upper…',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                const Text('Colour', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: colorOptions.map((c) => GestureDetector(
                    onTap: () => setS(() => colorValue = c),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: colorValue == c
                            ? Border.all(width: 3,
                                color: Theme.of(ctx).colorScheme.onSurface)
                            : null,
                      ),
                    ),
                  )).toList(),
                ),
                if (program.isWeekly) ...[
                  const SizedBox(height: 16),
                  const Text('Days', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  _WeekdayPicker(
                    onChanged: (days) =>
                        setS(() => weekDays = days.join(',')),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && nameCtrl.text.trim().isNotEmpty) {
      final orderIndex = program.sessions.length;
      final sessionId = await ref
          .read(programRepositoryProvider)
          .addSession(
            programId: program.id,
            name: nameCtrl.text.trim(),
            colorValue: colorValue,
            weekDays: weekDays,
            orderIndex: orderIndex,
          );
      if (mounted) {
        context.push(
          '/workout/programs/${program.id}/session/$sessionId',
        );
      }
    }
  }

  Future<void> _deleteProgram() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Program?'),
        content:
            const Text('This removes the plan but keeps your workout history.'),
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
    if (confirm == true && mounted) {
      await ref
          .read(programRepositoryProvider)
          .deleteProgram(program.id);
      if (mounted) context.pop();
    }
  }

  Future<void> _setActive() async {
    await ref
        .read(programRepositoryProvider)
        .setActiveProgram(program.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${program.name}" set as active program'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteSession(ProgramSessionModel session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${session.name}"?'),
        content: const Text(
            'Removes this session type. Past workouts are not affected.'),
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
      await ref
          .read(programRepositoryProvider)
          .deleteSession(session.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sessions = program.sessions;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(program.name),
            Text(
              program.isRotating
                  ? '${sessions.length}-day rotating'
                  : 'Weekly split',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withAlpha(140),
                  ),
            ),
          ],
        ),
        actions: [
          if (!program.isActive)
            TextButton(
              onPressed: _setActive,
              child: const Text('Set Active'),
            ),
          PopupMenuButton<String>(
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Program'),
              ),
            ],
            onSelected: (v) {
              if (v == 'delete') _deleteProgram();
            },
          ),
        ],
      ),

      body: sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.playlist_add_rounded,
                      size: 64, color: cs.onSurface.withAlpha(60)),
                  const SizedBox(height: 16),
                  Text(
                    'No session types yet',
                    style: TextStyle(color: cs.onSurface.withAlpha(140)),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _addSession,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Session Type'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: sessions.length,
              itemBuilder: (ctx, i) {
                final session = sessions[i];
                return _SessionCard(
                  session: session,
                  splitType: program.splitType,
                  onTap: () => context.push(
                    '/workout/programs/${program.id}/session/${session.id}',
                  ),
                  onStart: () => _startSession(session),
                  onDelete: () => _deleteSession(session),
                );
              },
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSession,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Session'),
      ),
    );
  }
}

// ── Session summary card ──────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.splitType,
    required this.onTap,
    required this.onStart,
    required this.onDelete,
  });

  final ProgramSessionModel session;
  final String splitType;
  final VoidCallback onTap;
  final VoidCallback onStart;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = session.color;
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (splitType == 'weekly' &&
                      session.weekDayLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(session.weekDayLabel,
                          style: const TextStyle(fontSize: 11)),
                    ),
                  IconButton(
                    icon: const Icon(Icons.play_arrow_rounded),
                    iconSize: 22,
                    color: cs.primary,
                    tooltip: 'Start workout',
                    onPressed: onStart,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded),
                    iconSize: 20,
                    color: cs.onSurface.withAlpha(120),
                    onPressed: onDelete,
                  ),
                ],
              ),

              if (session.exercises.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...session.exercises
                    .take(4)
                    .map((e) => _ExerciseRow(exercise: e)),
                if (session.exercises.length > 4)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 20),
                    child: Text(
                      '+ ${session.exercises.length - 4} more',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withAlpha(120)),
                    ),
                  ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'No exercises — tap to add',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withAlpha(120)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise});
  final ProgramExerciseModel exercise;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6,
              color: cs.onSurface.withAlpha(100)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              exercise.exerciseName,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            '${exercise.volumeLabel}  •  ${exercise.restLabel}',
            style: TextStyle(
                fontSize: 11, color: cs.onSurface.withAlpha(140)),
          ),
        ],
      ),
    );
  }
}

// ── Weekday picker widget ─────────────────────────────────────────────────────

class _WeekdayPicker extends StatefulWidget {
  const _WeekdayPicker({required this.onChanged});
  final ValueChanged<List<int>> onChanged;

  @override
  State<_WeekdayPicker> createState() => _WeekdayPickerState();
}

class _WeekdayPickerState extends State<_WeekdayPicker> {
  final Set<int> _selected = {};
  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(7, (i) {
        final day = i + 1;
        final sel = _selected.contains(day);
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (sel) { _selected.remove(day); } else { _selected.add(day); }
              });
              widget.onChanged(_selected.toList()..sort());
            },
            child: CircleAvatar(
              radius: 16,
              backgroundColor:
                  sel ? cs.primary : cs.surfaceContainerHighest,
              child: Text(
                _labels[i],
                style: TextStyle(
                  fontSize: 12,
                  color: sel ? cs.onPrimary : cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
