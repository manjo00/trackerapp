import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The persistent shell that wraps every tab screen.
///
/// [navigationShell] is provided by go_router's [StatefulShellRoute].
/// It knows which branch (tab) is currently active and handles switching.
class HomeShell extends StatelessWidget {
  const HomeShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,

      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,

        onDestinationSelected: (int index) {
          navigationShell.goBranch(
            index,
            // Tapping the already-active tab scrolls back to root.
            initialLocation: index == navigationShell.currentIndex,
          );
        },

        destinations: const [
          // 0 — Today
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny_rounded),
            label: 'Today',
          ),

          // 1 — Habits
          NavigationDestination(
            icon: Icon(Icons.radio_button_unchecked_rounded),
            selectedIcon: Icon(Icons.task_alt_rounded),
            label: 'Habits',
          ),

          // 2 — Tasks
          NavigationDestination(
            icon: Icon(Icons.check_box_outline_blank_rounded),
            selectedIcon: Icon(Icons.check_box_rounded),
            label: 'Tasks',
          ),

          // 3 — Planner
          NavigationDestination(
            icon: Icon(Icons.calendar_today_rounded),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Planner',
          ),
        ],
      ),
    );
  }
}
