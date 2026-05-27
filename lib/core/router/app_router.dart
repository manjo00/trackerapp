import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/habits/presentation/screens/habit_list_screen.dart';
import '../../features/habits/presentation/screens/add_habit_screen.dart';
import '../../features/tasks/presentation/screens/task_list_screen.dart';
import '../../features/tasks/presentation/screens/add_task_screen.dart';
import '../../features/planner/presentation/screens/planner_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/today/presentation/screens/today_screen.dart';
import 'shell_scaffold.dart';

/// The single [GoRouter] instance for the whole app.
///
/// Route tree:
/// ```
///  StatefulShellRoute   ← HomeShell (bottom nav persists across tabs)
///    /today             ← TodayScreen      (index 0, default tab)
///    /habits            ← HabitListScreen  (index 1)
///    /tasks             ← TaskListScreen   (index 2)
///    /planner           ← PlannerScreen    (index 3, placeholder)
///
///  /habits/add          ← AddHabitScreen  (outside shell — hides bottom nav)
///  /tasks/add           ← AddTaskScreen   (outside shell — hides bottom nav)
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
  ],
);
