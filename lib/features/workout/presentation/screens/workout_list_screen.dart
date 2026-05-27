import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/workout_session_model.dart';
import '../providers/workout_providers.dart';

/// The main Workout tab — shows a stats header and the history of past sessions.
///
/// FAB starts a new workout and navigates to the active-workout screen.
class WorkoutListScreen extends ConsumerWidget {
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(allWorkoutSessionsProvider);
    final weekAsync = ref.watch(sessionsThisWeekProvider);
    final activeState = ref.watch(activeWorkoutProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sessions) {
          return CustomScrollView(
            slivers: [
              // ── Stats header ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _StatsHeader(
                  weekSessions: weekAsync.valueOrNull ?? 0,
                  totalSets: sessions.fold(0, (sum, s) => sum + s.totalSets),
                ),
              ),

              // ── Active workout banner (if a session is in progress) ────
              if (activeState.valueOrNull != null)
                SliverToBoxAdapter(
                  child: _ActiveBanner(
                    onResume: () => context.push('/workout/active'),
                  ),
                ),

              // ── Session list ─────────────────────────────────────────────
              if (sessions.isEmpty)
                const SliverFillRemaining(
                  child: _EmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 88),
                  sliver: SliverList.separated(
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, i) =>
                        _SessionTile(session: sessions[i]),
                  ),
                ),
            ],
          );
        },
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // If a workout is already running, just resume it.
          final active = ref.read(activeWorkoutProvider).valueOrNull;
          if (active != null) {
            context.push('/workout/active');
            return;
          }
          await ref.read(activeWorkoutProvider.notifier).start();
          if (context.mounted) context.push('/workout/active');
        },
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(
          ref.watch(activeWorkoutProvider).valueOrNull != null
              ? 'Resume Workout'
              : 'Start Workout',
        ),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
    );
  }
}

// ── Stats header ──────────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({
    required this.weekSessions,
    required this.totalSets,
  });

  final int weekSessions;
  final int totalSets;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            value: '$weekSessions',
            label: 'This week',
            icon: Icons.calendar_today_rounded,
          ),
          Container(
            width: 1,
            height: 40,
            color: cs.onPrimaryContainer.withAlpha(40),
          ),
          _StatItem(
            value: '$totalSets',
            label: 'Total sets',
            icon: Icons.fitness_center_rounded,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: cs.onPrimaryContainer),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: cs.onPrimaryContainer.withAlpha(180),
              ),
        ),
      ],
    );
  }
}

// ── Active-workout resume banner ──────────────────────────────────────────────

class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner({required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onResume,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.play_circle_rounded,
                color: cs.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Workout in progress — tap to resume',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

// ── Session tile ──────────────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final WorkoutSessionModel session;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Parse date string "yyyy-MM-dd" for display.
    final DateTime date = DateTime.tryParse(session.date) ?? DateTime.now();
    final String dateLabel = DateFormat('EEE, d MMM').format(date);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      title: Row(
        children: [
          Text(
            session.displayName,
            style: textTheme.titleMedium,
          ),
          if (session.hasPr) ...[
            const SizedBox(width: 6),
            const Text('🏆', style: TextStyle(fontSize: 14)),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            dateLabel,
            style: textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withAlpha(160),
            ),
          ),
          const SizedBox(height: 4),
          // Exercise name chips (first 3, then "+N more")
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _buildExerciseChips(context, session),
          ),
        ],
      ),
      trailing: Text(
        '${session.totalSets} sets',
        style: textTheme.labelMedium?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<Widget> _buildExerciseChips(
      BuildContext context, WorkoutSessionModel session) {
    final cs = Theme.of(context).colorScheme;
    final names = session.exerciseNames;
    const maxShow = 3;
    final chips = <Widget>[];

    for (int i = 0; i < names.length && i < maxShow; i++) {
      chips.add(_SessionChip(label: names[i]));
    }
    if (names.length > maxShow) {
      chips.add(
        _SessionChip(
          label: '+${names.length - maxShow} more',
          color: cs.surfaceContainerHighest,
        ),
      );
    }
    return chips;
  }
}

class _SessionChip extends StatelessWidget {
  const _SessionChip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color ?? cs.primaryContainer.withAlpha(120),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
            'No workouts yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: cs.onSurface.withAlpha(140),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap Start Workout to log your first session',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withAlpha(100),
                ),
          ),
        ],
      ),
    );
  }
}
