import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/habits/presentation/screens/habit_list_screen.dart';
import '../../features/habits/presentation/screens/add_habit_screen.dart';
import '../../features/tasks/presentation/screens/tasks_screen.dart';
import '../../features/planner/presentation/screens/planner_screen.dart';
import 'shell_scaffold.dart';

/// The single [GoRouter] instance for the whole app.
///
/// Route tree:
/// ```
///  StatefulShellRoute   ← HomeShell (bottom nav persists across tabs)
///    /habits            ← HabitListScreen  (Step 9)
///    /tasks             ← TasksScreen      (placeholder)
///    /planner           ← PlannerScreen    (placeholder)
///
///  /habits/add          ← AddHabitScreen   (Step 10, outside shell)
/// ```
///
/// Routes outside [StatefulShellRoute] push full-screen without the bottom nav.
final GoRouter appRouter = GoRouter(
  initialLocation: '/habits',
  routes: [
    // ── Tabbed shell ──────────────────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      // builder receives the navigationShell object that knows the active tab.
      builder: (BuildContext context, GoRouterState state,
          StatefulNavigationShell navigationShell) {
        return HomeShell(navigationShell: navigationShell);
      },

      branches: [
        // Branch 0 — Habits
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

        // Branch 1 — Tasks (placeholder)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tasks',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: TasksScreen(),
              ),
            ),
          ],
        ),

        // Branch 2 — Planner (placeholder)
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

    // Add Habit — pushed from HabitListScreen's FAB.
    GoRoute(
      path: '/habits/add',
      builder: (context, state) => const AddHabitScreen(),
    ),
  ],
);
