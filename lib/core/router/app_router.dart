import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/habits/data/models/habit_model.dart';
import '../../features/habits/presentation/screens/habit_list_screen.dart';
import '../../features/habits/presentation/screens/add_habit_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/archive/presentation/screens/archived_screen.dart';
import '../../features/notes/presentation/screens/note_editor_screen.dart';
import '../../features/notes/presentation/screens/notebook_detail_screen.dart';
import '../../features/notes/presentation/screens/notes_overview_screen.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/tasks/presentation/screens/add_task_screen.dart';
import '../../features/tasks/presentation/screens/list_detail_screen.dart';
import '../../features/tasks/presentation/screens/lists_overview_screen.dart';
import '../../features/tasks/presentation/screens/quick_add_task_screen.dart';
import '../../features/planner/presentation/screens/planner_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/shifts/presentation/screens/shift_schedule_screen.dart';
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
///    /today             ← TodayScreen        (branch 0, drawer)
///    /home              ← HomeScreen         (branch 1, default tab)
///    /habits            ← HabitListScreen    (branch 2)
///    /lists             ← TaskListScreen     (branch 3 — ListsOverview soon)
///    /planner           ← PlannerScreen      (branch 4)
///    /trackers          ← TrackersScreen     (branch 5)
///    /workout           ← WorkoutHomeScreen  (branch 6)
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
/// Set by main() (from the startup-tab preference) BEFORE the lazy
/// [appRouter] global below is first touched. '/home' when unset.
String appInitialLocation = '/home';

final GoRouter appRouter = GoRouter(
  initialLocation: appInitialLocation,
  // Home-screen widget deep links arrive as custom-scheme URIs
  // (e.g. uplan://add_task). Translate them to real in-app routes here,
  // before go_router tries — and fails — to match them as paths.
  redirect: (BuildContext context, GoRouterState state) {
    final Uri uri = state.uri;
    if (uri.host == 'add_task' || uri.toString().contains('add_task')) {
      return '/quick-add';
    }
    // Rest-timer notification tap → continue the active workout.
    if (uri.host == 'open_workout' || uri.toString().contains('open_workout')) {
      return '/workout/active';
    }
    // Some launch paths report a bare "/" which has no route — send the
    // user's startup tab.
    if (uri.path.isEmpty || uri.path == '/') {
      return appInitialLocation;
    }
    return null;
  },
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

        // Branch 1 — Home (dashboard landing view)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomeScreen(),
              ),
            ),
          ],
        ),

        // Branch 2 — Habits
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

        // Branch 3 — Lists overview ("All tasks" + user lists)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/lists',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ListsOverviewScreen(),
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
      path: '/archived',
      builder: (context, state) => const ArchivedScreen(),
    ),

    // ── Notes (full-screen, no bottom nav) ────────────────────────────────
    GoRoute(
      path: '/notes',
      builder: (context, state) => const NotesOverviewScreen(),
    ),
    // More specific than '/notes/:id' — listed first so '/notes/notebook/5'
    // matches here. Path param 'unfiled' = the null-notebook bucket.
    GoRoute(
      path: '/notes/notebook/:id',
      builder: (context, state) {
        final String raw = state.pathParameters['id'] ?? 'unfiled';
        final int? notebookId = raw == 'unfiled' ? null : int.tryParse(raw);
        return NotebookDetailScreen(notebookId: notebookId);
      },
    ),
    GoRoute(
      path: '/notes/:id',
      builder: (context, state) =>
          NoteEditorScreen(noteId: int.parse(state.pathParameters['id']!)),
    ),

    GoRoute(
      path: '/schedule',
      builder: (context, state) => const ShiftScheduleScreen(),
    ),

    // Lightweight quick-add half-sheet, opened by the home-screen widget "+".
    GoRoute(
      path: '/quick-add',
      builder: (context, state) => const QuickAddTaskScreen(),
    ),

    GoRoute(
      path: '/tasks/add',
      // state.extra is either an [AddTaskArgs] (list/section/date pre-fills)
      // or — back-compat with older call sites — a bare "yyyy-MM-dd" string.
      builder: (context, state) {
        final Object? extra = state.extra;
        if (extra is AddTaskArgs) {
          return AddTaskScreen(
            initialDate: extra.initialDate,
            initialTime: extra.initialTime,
            initialListId: extra.listId,
            initialSectionId: extra.sectionId,
          );
        }
        return AddTaskScreen(initialDate: extra as String?);
      },
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

    // ── List detail (full-screen, no bottom nav) ──────────────────────────

    GoRoute(
      path: '/lists/:id',
      builder: (context, state) {
        final int listId = int.parse(state.pathParameters['id'] ?? '0');
        return ListDetailScreen(listId: listId);
      },
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
