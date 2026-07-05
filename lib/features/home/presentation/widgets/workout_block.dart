import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/settings/settings_provider.dart';
import '../../../workout/presentation/providers/program_providers.dart';
import '../../../workout/presentation/providers/workout_providers.dart';
import '../../../workout/presentation/widgets/week_attendance_strip.dart';
import '../../../workout/presentation/workout_actions.dart';

/// The Home dashboard's workout block: today's suggested session with a
/// Start/Resume button plus the this-week attendance strip. All data and
/// actions are the same providers the Workout tab uses.
class WorkoutBlock extends ConsumerWidget {
  const WorkoutBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final program = ref.watch(activeProgramProvider).valueOrNull;
    final suggested = ref.watch(todaysSuggestedSessionProvider).valueOrNull;
    final sessions =
        ref.watch(allWorkoutSessionsProvider).valueOrNull ?? const [];
    final bool inProgress =
        ref.watch(activeWorkoutProvider).valueOrNull != null;

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
}
