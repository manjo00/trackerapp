import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/habits/data/models/habit_model.dart';
import '../../features/habits/presentation/screens/habit_list_screen.dart';
import '../../features/habits/presentation/screens/add_habit_screen.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/tasks/presentation/screens/task_list_screen.dart';
import '../../features/tasks/presentation/screens/add_task_screen.dart';
import '../../features/planner/presentation/screens/planner_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/today/presentation/screens/today_screen.dart';
import '../../features/trackers/data/models/tracker_item_model.dart';
import '../../features/trackers/data/models/tracker_model.dart';
import '../../features/trackers/presentation/screens/trackers_screen.dart';
import '../../features/trackers/presentation/screens/add_tracker_screen.dart';
import '../../features/trackers/presentation/screens/tracker_detail_screen.dart';
import '../../features/trackers/presentation/screens/log_entry_screen.dart';
import '../../features/workout/presentation/screens/active_workout_screen.dart';
import '../../features/workout/presentation/screens/create_program_screen.dart';
import '../../features/workout/presentation/screens/exercise_picker_screen.dart';
import '../../features/workout/presentation/screens/program_detail_screen.dart';
import '../../features/workout/presentation/screens/program_session_editor_screen.dart';
import '../../features/workout/presentation/screens/workout_home_screen.dart';
import 'shell_scaffold.dart';

/// The single [GoRouter] instance for the whole app.
///
/// Route tree:
/// ```
///  StatefulShellRoute   ← HomeShell (bottom nav persists across tabs)
///    /today             ← TodayScreen        (index 0, default tab)
///    /habits            ← HabitListScreen    (index 1)
///    /tasks             ← TaskListScreen     (index 2)
///    /planner           ← PlannerScreen      (index 3)
///    /trackers          ← TrackersScreen     (index 4)
///    /workout           ← WorkoutHomeScreen  (index 5)
///
///  /habits/add                          ← AddHabitScreen              (outside shell)
///  /tasks/add                           ← AddTaskScreen               (outside shell)
///  /trackers/add                        ← AddTrackerScreen            (outside shell)
///  /trackers/:id                        ← TrackerDetailScreen         (outside shell)
///  /trackers/:id/log                    ← LogEntryScreen              (outside shell)
///  /workout/active                      ← ActiveWorkoutScreen         (outside shell)
///  /workout/exercises                   ← ExercisePickerScreen        (outside shell)
///  /workout/programs/create             ← CreateProgramScreen         (outside shell)
///  /workout/programs/:id                ← ProgramDetailScreen         (outside shell)
///  /workout/programs/:id/session/:sid   ← ProgramSessionEditorScreen  (outside shell)
/// ```
final GoRouter appRouter = GoRouter(
  initialLocation: '/today',
  routes: [
    // ── Tabbed shell ──────────────────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state,
          StatefulNavigationShell navigationShell) {
        return HomeShell(navigationShell: navigationShell);
      },

      branches: [
        // Branch 0 — Today
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/today',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: TodayScreen(),
              ),
            ),
          ],
        ),

        // Branch 1 — Habits
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/habits',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HabitListScreen(),
              ),
            ),
          ],
        ),

        // Branch 2 — Tasks
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tasks',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: TaskListScreen(),
              ),
            ),
          ],
        ),

        // Branch 3 — Planner (placeholder)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/planner',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: PlannerScreen(),
              ),
            ),
          ],
        ),

        // Branch 4 — Trackers
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/trackers',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: TrackersScreen(),
              ),
            ),
          ],
        ),

        // Branch 5 — Workout
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/workout',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: WorkoutHomeScreen(),
              ),
            ),
          ],
        ),
      ],
    ),

    // ── Full-screen routes (no bottom nav) ────────────────────────────────

    GoRoute(
      path: '/habits/add',
      builder: (context, state) => const AddHabitScreen(),
    ),

    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),

    GoRoute(
      path: '/tasks/add',
      // state.extra carries the pre-filled date string ("yyyy-MM-dd") when
      // opened via long-press from the planner. Null when opened from the FAB.
      builder: (context, state) => AddTaskScreen(
        initialDate: state.extra as String?,
      ),
    ),

    GoRoute(
      path: '/tasks/edit',
      // state.extra is a TaskModel passed from TaskTile's long-press.
      builder: (context, state) => AddTaskScreen(
        task: state.extra as TaskModel?,
      ),
    ),

    GoRoute(
      path: '/habits/edit',
      // state.extra is a HabitModel passed from HabitTile's long-press.
      builder: (context, state) => AddHabitScreen(
        habit: state.extra as HabitModel?,
      ),
    ),

    // ── Tracker routes (full-screen, no bottom nav) ───────────────────────

    GoRoute(
      path: '/trackers/add',
      builder: (context, state) => const AddTrackerScreen(),
    ),

    GoRoute(
      path: '/trackers/:id',
      builder: (context, state) {
        final int trackerId = int.parse(state.pathParameters['id']!);
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final typeRaw = extra['trackerType'];
        final trackerType = typeRaw is TrackerType
            ? typeRaw
            : TrackerType.dailyChecklist;
        return TrackerDetailScreen(
          trackerId: trackerId,
          trackerName: extra['name'] as String? ?? '',
          trackerIcon: extra['icon'] as String? ?? '📋',
          trackerType: trackerType,
        );
      },
    ),

    GoRoute(
      path: '/trackers/:id/log',
      builder: (context, state) {
        final int trackerId = int.parse(state.pathParameters['id']!);
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final items =
            (extra['items'] as List<TrackerItemModel>?) ?? const [];
        final typeRaw = extra['trackerType'];
        final trackerType = typeRaw is TrackerType
            ? typeRaw
            : TrackerType.dailyChecklist;
        return LogEntryScreen(
          trackerId: trackerId,
          trackerName: extra['name'] as String? ?? '',
          trackerIcon: extra['icon'] as String? ?? '📋',
          items: items,
          trackerType: trackerType,
          preChecked: extra['checkedItemIds'] as Set<int>?,
        );
      },
    ),

    // ── Workout full-screen routes ─────────────────────────────────────────

    GoRoute(
      path: '/workout/active',
      builder: (context, state) => const ActiveWorkoutScreen(),
    ),

    GoRoute(
      path: '/workout/exercises',
      builder: (context, state) => const ExercisePickerScreen(),
    ),

    GoRoute(
      path: '/workout/programs/create',
      builder: (context, state) => const CreateProgramScreen(),
    ),

    GoRoute(
      path: '/workout/programs/:id',
      builder: (context, state) {
        final programId = int.parse(state.pathParameters['id']!);
        return ProgramDetailScreen(programId: programId);
      },
    ),

    GoRoute(
      path: '/workout/programs/:id/session/:sid',
      builder: (context, state) {
        final programId = int.parse(state.pathParameters['id']!);
        final sessionId = int.parse(state.pathParameters['sid']!);
        return ProgramSessionEditorScreen(
          programId: programId,
          sessionId: sessionId,
        );
      },
    ),
  ],
);
