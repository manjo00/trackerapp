import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/program_model.dart';
import '../../data/models/program_session_model.dart';
import '../../data/models/workout_session_model.dart';
import '../providers/program_providers.dart';
import '../providers/workout_providers.dart';

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

            // ── Program card / empty state ────────────────────────────────
            SliverToBoxAdapter(
              child: program == null
                  ? _NoProgramCard(
                      onSetUp: () => context.push('/workout/programs/create'),
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
  }) async {
    // If already active, just resume.
    final active = ref.read(activeWorkoutProvider).valueOrNull;
    if (active != null) {
      context.push('/workout/active');
      return;
    }
    await ref.read(activeWorkoutProvider.notifier).start(
          programSessionId: session?.id,
          programExercises: session?.exercises ?? [],
          programSessionName: session?.name,
        );
    if (context.mounted) context.push('/workout/active');
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
