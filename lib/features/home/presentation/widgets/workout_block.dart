import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/settings/settings_provider.dart';
import '../../../workout/data/models/group_score.dart';
import '../../../workout/data/models/quick_start_templates.dart';
import '../../../workout/presentation/providers/program_providers.dart';
import '../../../workout/presentation/providers/workout_providers.dart';
import '../../../workout/presentation/widgets/week_attendance_strip.dart';
import '../../../workout/presentation/workout_actions.dart';

/// The Home dashboard's workout block. Mode-aware, mirroring the Workout
/// tab: in the weekly-targets experiment it shows the muscles-met count +
/// quick-start chips; in classic program mode, today's suggested session
/// with Start/Resume + the this-week attendance strip.
class WorkoutBlock extends ConsumerWidget {
  const WorkoutBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool targetsMode =
        ref.watch(settingsProvider.select((s) => s.experimentalTargets)) &&
            ref.watch(workoutTargetsModeProvider);
    final program = ref.watch(activeProgramProvider).valueOrNull;
    final suggested = ref.watch(todaysSuggestedSessionProvider).valueOrNull;
    final sessions =
        ref.watch(allWorkoutSessionsProvider).valueOrNull ?? const [];
    final bool inProgress =
        ref.watch(activeWorkoutProvider).valueOrNull != null;

    if (targetsMode) return _targetsCard(context, ref, cs, inProgress);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // No active program: a single tile into the Workout tab.
        if (program == null)
          Card(
            child: ListTile(
              leading: Icon(Icons.fitness_center_rounded, color: cs.primary),
              title: const Text('Workout'),
              subtitle: const Text('Set up a program to train from Home'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/workout'),
            ),
          )
        else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          inProgress
                              ? 'Workout in progress'
                              : (suggested?.name ?? 'Custom session'),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          inProgress
                              ? 'Jump back in'
                              : (suggested != null
                                  ? "Today's session · ${program.name}"
                                  : program.name),
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withAlpha(140),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => inProgress
                        ? context.push('/workout/active')
                        : startProgramSession(context, ref,
                            session: suggested),
                    icon: Icon(
                        inProgress
                            ? Icons.play_circle_rounded
                            : Icons.play_arrow_rounded,
                        size: 18),
                    label: Text(inProgress ? 'Resume' : 'Start'),
                  ),
                ],
              ),
            ),
          ),
          WeekAttendanceStrip(
            program: program,
            loggedIds: loggedThisWeek(
              sessions,
              sundayStart: ref
                  .watch(settingsProvider.select((s) => s.weekStartsSunday)),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  /// Weekly-targets flavour: muscles-met summary + one-tap quick starts —
  /// the same session types the Workout tab's quick-start row offers.
  Widget _targetsCard(
      BuildContext context, WidgetRef ref, ColorScheme cs, bool inProgress) {
    final List<MuscleScore> scores = ref.watch(weeklyScoreboardProvider);
    final int met = scores.where((s) => s.fullyMet).length;
    final int total = scores.where((s) => s.frequencyTarget > 0).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    inProgress ? 'Workout in progress' : 'This week',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '$met / $total muscles',
                  style: TextStyle(
                      fontSize: 13, color: cs.onSurface.withAlpha(150)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (inProgress)
              FilledButton.icon(
                onPressed: () => context.push('/workout/active'),
                icon: const Icon(Icons.play_circle_rounded, size: 18),
                label: const Text('Resume'),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final QuickStartTemplate t in kQuickStartTemplates)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilledButton.tonalIcon(
                          onPressed: () =>
                              startQuickTemplate(context, ref, t),
                          icon:
                              const Icon(Icons.play_arrow_rounded, size: 18),
                          label: Text(t.name),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
