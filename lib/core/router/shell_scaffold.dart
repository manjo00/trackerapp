import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The persistent shell that wraps every tab screen.
///
/// [navigationShell] is provided by go_router's [StatefulShellRoute].
/// It knows which branch (tab) is currently active and handles switching.
///
/// Why [StatelessWidget]: the shell itself has no state — go_router's
/// [StatefulShellRoute] is the source of truth for the active index.
class HomeShell extends StatelessWidget {
  const HomeShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The inner page is rendered here — go_router swaps it on tab change.
      body: navigationShell,

      bottomNavigationBar: NavigationBar(
        // go_router tells us which branch is showing.
        selectedIndex: navigationShell.currentIndex,

        // Called when the user taps a nav item.
        // goBranch() switches the active branch while preserving each
        // branch's own navigation stack.
        onDestinationSelected: (int index) {
          navigationShell.goBranch(
            index,
            // If the user taps the *already-active* tab, scroll back to
            // the root of that branch (like tapping the tab again in Instagram).
            initialLocation: index == navigationShell.currentIndex,
          );
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.radio_button_unchecked_rounded),
            selectedIcon: Icon(Icons.task_alt_rounded),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_box_outline_blank_rounded),
            selectedIcon: Icon(Icons.check_box_rounded),
            label: 'Tasks',
          ),
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
