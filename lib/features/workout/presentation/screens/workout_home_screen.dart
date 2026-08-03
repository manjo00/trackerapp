import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/program_model.dart';
import '../../data/models/program_session_model.dart';
import '../../data/models/quick_start_templates.dart';
import '../../data/models/workout_session_model.dart';
import '../../../../core/settings/settings_provider.dart';
import '../providers/program_providers.dart';
import '../providers/workout_providers.dart';
import '../widgets/week_attendance_strip.dart';
import '../widgets/weekly_scoreboard_card.dart';
import '../workout_actions.dart';

/// The main Workout tab.
///
/// Shows:
///   • The active program card with today's suggested session
///   • Weekly compliance dots (for weekly splits) or rotation progress
///   • "Train Today" / "Train [Session Name]" primary CTA
///   • Recent session history
///   • Empty state with "Set up program" CTA when no program is active
class WorkoutHomeScreen extends ConsumerWidget {
  const WorkoutHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programAsync = ref.watch(activeProgramProvider);
    final suggestedAsync = ref.watch(todaysSuggestedSessionProvider);
    final sessionsAsync = ref.watch(allWorkoutSessionsProvider);
    final activeWorkout = ref.watch(activeWorkoutProvider).valueOrNull;
    // Weekly targets is an opt-in experiment (Settings → Labs). When off,
    // the Workout tab is always the classic Program view — no mode switch.
    final bool experimentOn =
        ref.watch(settingsProvider.select((s) => s.experimentalTargets));
    final bool targetsMode =
        experimentOn && ref.watch(workoutTargetsModeProvider);

    return Scaffold(
      body: programAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (program) => CustomScrollView(
          slivers: [
            // ── Active-workout resume banner ──────────────────────────────
            if (activeWorkout != null)
              SliverToBoxAdapter(
                child: _ResumeBanner(
                  onResume: () => context.push('/workout/active'),
                ),
              ),

            // ── Mode switch: Targets ⇄ Program (experiment only) ──────────
            if (experimentOn)
              SliverToBoxAdapter(
                child: _ModeToggle(
                  targetsMode: targetsMode,
                  onChanged: (v) =>
                      ref.read(workoutTargetsModeProvider.notifier).set(v),
                ),
              ),

            // ── Targets mode: scoreboard + quick start ────────────────────
            if (targetsMode) ...[
              const SliverToBoxAdapter(child: WeeklyScoreboardCard()),
              SliverToBoxAdapter(
                child: _QuickStartRow(
                  onStart: (t) => _startTemplate(context, ref, t),
                ),
              ),
            ],

            // ── Program mode: program card + attendance ───────────────────
            if (!targetsMode) ...[
              SliverToBoxAdapter(
                child: program == null
                    ? _NoProgramCard(
                        onSetUp: () =>
                            context.push('/workout/programs/create'),
                      )
                    : _ProgramCard(
                        program: program,
                        suggestedSession: suggestedAsync.valueOrNull,
                        onTrain: (session) => _startWorkout(
                          context,
                          ref,
                          session: session,
                        ),
                        onManage: () =>
                            context.push('/workout/programs/${program.id}'),
                      ),
              ),
              if (program != null && program.sessions.isNotEmpty)
                SliverToBoxAdapter(
                  child: WeekAttendanceStrip(
                    program: program,
                    loggedIds: loggedThisWeek(
                        sessionsAsync.valueOrNull ?? const [],
                        sundayStart: ref.watch(settingsProvider
                            .select((s) => s.weekStartsSunday))),
                  ),
                ),
            ],

            // ── My workouts: personal one-tap templates ───────────────────
            SliverToBoxAdapter(
              child: _MyWorkoutsSection(
                workouts: ref.watch(myWorkoutsProvider).valueOrNull ??
                    const <ProgramSessionModel>[],
                onStart: (s) => _startWorkout(context, ref, session: s),
                onEdit: (s) => context.push(
                    '/workout/programs/${s.programId}/session/${s.id}'),
                onDelete: (s) => _deleteMyWorkout(context, ref, s),
                onCreate: () => _createMyWorkout(context, ref),
              ),
            ),

            // ── History header ────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Text(
                  'Recent Sessions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // ── Session history ───────────────────────────────────────────
            sessionsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) =>
                  SliverToBoxAdapter(child: Text('Error: $e')),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No sessions logged yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.only(bottom: 100),
                  sliver: SliverList.separated(
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) => const Divider(
                        height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (ctx, i) =>
                        _SessionTile(session: sessions[i]),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // ── FAB: custom / freeform session ───────────────────────────────────
      floatingActionButton: FloatingActionButton(
        heroTag: 'workout_home_fab',
        onPressed: () => _startWorkout(context, ref),
        tooltip: 'Log custom session',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _startWorkout(
    BuildContext context,
    WidgetRef ref, {
    ProgramSessionModel? session,
  }) =>
      startProgramSession(context, ref, session: session);

  /// Starts an ad-hoc session from a quick-start template (shared logic
  /// lives in workout_actions.dart — also used by the Home workout block).
  Future<void> _startTemplate(
    BuildContext context,
    WidgetRef ref,
    QuickStartTemplate template,
  ) =>
      startQuickTemplate(context, ref, template);

  /// Name a new personal workout, then open the exercise editor on it.
  Future<void> _createMyWorkout(BuildContext context, WidgetRef ref) async {
    final TextEditingController ctrl = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New workout'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration:
              const InputDecoration(hintText: 'e.g. Chest & arms'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: const Text('Create')),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.isEmpty) return;
    final (int pid, int sid) =
        await ref.read(programRepositoryProvider).createMyWorkout(name);
    if (context.mounted) {
      context.push('/workout/programs/$pid/session/$sid');
    }
  }

  Future<void> _deleteMyWorkout(
    BuildContext context,
    WidgetRef ref,
    ProgramSessionModel workout,
  ) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete workout?'),
        content: Text('"${workout.name}" is removed from My workouts. '
            'Sessions you already logged with it are kept.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(programRepositoryProvider).deleteSession(workout.id);
  }
}

// ── My workouts section ───────────────────────────────────────────────────────

/// The user's own single-workout templates: tap to start, ✎ to edit,
/// long-press to delete, ＋ to make a new one.
class _MyWorkoutsSection extends StatelessWidget {
  const _MyWorkoutsSection({
    required this.workouts,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
    required this.onCreate,
  });

  final List<ProgramSessionModel> workouts;
  final void Function(ProgramSessionModel) onStart;
  final void Function(ProgramSessionModel) onEdit;
  final void Function(ProgramSessionModel) onDelete;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'My Workouts',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New'),
              ),
            ],
          ),
          if (workouts.isEmpty)
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onCreate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Text(
                    'Build your own workout once — start it in one tap, '
                    'edit it any time.',
                    style: TextStyle(
                        fontSize: 13, color: cs.onSurface.withAlpha(120)),
                  ),
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final ProgramSessionModel w in workouts)
                    InkWell(
                      onTap: () => onStart(w),
                      onLongPress: () => onDelete(w),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.play_circle_fill_rounded,
                                color: cs.primary, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(w.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                    w.exercises.isEmpty
                                        ? 'No exercises yet — tap ✎'
                                        : '${w.exercises.length} exercise'
                                            '${w.exercises.length == 1 ? '' : 's'}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            cs.onSurface.withAlpha(140)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_rounded,
                                  size: 20,
                                  color: cs.onSurface.withAlpha(150)),
                              tooltip: 'Edit workout',
                              onPressed: () => onEdit(w),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// (loggedThisWeek + the attendance strip live in
// widgets/week_attendance_strip.dart — shared with the Home dashboard.)

// ── Mode toggle ───────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.targetsMode, required this.onChanged});

  final bool targetsMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SegmentedButton<bool>(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size.fromHeight(38),
        ),
        segments: const [
          ButtonSegment(
            value: true,
            icon: Icon(Icons.track_changes_rounded, size: 16),
            label: Text('Targets'),
          ),
          ButtonSegment(
            value: false,
            icon: Icon(Icons.view_week_rounded, size: 16),
            label: Text('Program'),
          ),
        ],
        selected: {targetsMode},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

// ── Quick-start row ─────────────────────────────────────────────────────────────

class _QuickStartRow extends StatelessWidget {
  const _QuickStartRow({required this.onStart});

  final void Function(QuickStartTemplate template) onStart;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK START',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: cs.onSurface.withAlpha(130),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final QuickStartTemplate t in kQuickStartTemplates)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilledButton.tonalIcon(
                      onPressed: () => onStart(t),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(t.name),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Resume banner ─────────────────────────────────────────────────────────────

class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({required this.onResume});
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onResume,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.play_circle_rounded, color: cs.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Workout in progress — tap to resume',
                style: TextStyle(
                  color: cs.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: cs.onTertiaryContainer),
          ],
        ),
      ),
    );
  }
}

// ── No-program card ───────────────────────────────────────────────────────────

class _NoProgramCard extends StatelessWidget {
  const _NoProgramCard({required this.onSetUp});
  final VoidCallback onSetUp;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: cs.outline.withAlpha(60)),
      ),
      child: Column(
        children: [
          Icon(Icons.fitness_center_rounded,
              size: 48, color: cs.primary),
          const SizedBox(height: 16),
          Text(
            'Set up your workout plan',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose from PPL, Upper/Lower, or build your own split',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withAlpha(160),
                ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onSetUp,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Program'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(200, 48),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Program card ──────────────────────────────────────────────────────────────

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.suggestedSession,
    required this.onTrain,
    required this.onManage,
  });

  final ProgramModel program;
  final ProgramSessionModel? suggestedSession;
  final ValueChanged<ProgramSessionModel?> onTrain;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final session = suggestedSession;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        program.isRotating
                            ? '${program.sessions.length}-day rotating'
                            : 'Weekly split',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color:
                                  cs.onPrimaryContainer.withAlpha(180),
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.settings_rounded,
                      color: cs.onPrimaryContainer.withAlpha(160)),
                  onPressed: onManage,
                  tooltip: 'Manage program',
                ),
              ],
            ),
          ),

          // Session chips row
          if (program.sessions.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: program.sessions.map((s) {
                  final isToday = s.id == session?.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _SessionChip(
                        session: s, isHighlighted: isToday),
                  );
                }).toList(),
              ),
            ),

          // Today's session info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: session == null
                ? Text(
                    program.isWeekly
                        ? 'Rest day — no session scheduled today'
                        : 'All sessions complete for today',
                    style: TextStyle(
                        color: cs.onPrimaryContainer.withAlpha(160)),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: session.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Today: ${session.name}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      if (session.exercises.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          session.exercises
                              .take(3)
                              .map((e) => e.exerciseName)
                              .join(' · ')
                            + (session.exercises.length > 3
                                ? ' +${session.exercises.length - 3} more'
                                : ''),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    cs.onPrimaryContainer.withAlpha(180),
                              ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => onTrain(session),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text('Train ${session.name}'),
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SessionChip extends StatelessWidget {
  const _SessionChip({required this.session, required this.isHighlighted});
  final ProgramSessionModel session;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final color = session.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlighted
            ? color
            : color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withAlpha(isHighlighted ? 0 : 120),
        ),
      ),
      child: Text(
        session.name,
        style: TextStyle(
          color: isHighlighted ? Colors.white : color,
          fontWeight:
              isHighlighted ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Recent session tile ───────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});
  final WorkoutSessionModel session;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final date = DateTime.tryParse(session.date) ?? DateTime.now();
    final dateLabel = DateFormat('EEE, d MMM').format(date);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Row(
        children: [
          Text(session.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          if (session.hasPr) ...[
            const SizedBox(width: 6),
            const Text('🏆', style: TextStyle(fontSize: 13)),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(dateLabel,
              style: TextStyle(
                  color: cs.onSurface.withAlpha(140),
                  fontSize: 12)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: _buildChips(context, session),
          ),
        ],
      ),
      trailing: Text(
        '${session.totalSets} sets',
        style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13),
      ),
    );
  }

  List<Widget> _buildChips(
      BuildContext context, WorkoutSessionModel session) {
    final cs = Theme.of(context).colorScheme;
    final names = session.exerciseNames;
    const max = 3;
    final chips = <Widget>[];
    for (int i = 0; i < names.length && i < max; i++) {
      chips.add(_MiniChip(label: names[i]));
    }
    if (names.length > max) {
      chips.add(_MiniChip(
        label: '+${names.length - max} more',
        color: cs.surfaceContainerHighest,
      ));
    }
    return chips;
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? cs.primaryContainer.withAlpha(100),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
    );
  }
}
