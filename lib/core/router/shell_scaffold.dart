import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../settings/app_settings.dart';
import '../settings/settings_provider.dart';

/// The persistent shell that wraps every tab screen.
///
/// Changed from [StatelessWidget] to [ConsumerWidget] so it can watch
/// [settingsProvider] and rebuild whenever the user changes tab visibility.
///
/// The key challenge: [StatefulShellRoute] always has 4 branches (indices
/// 0–3), but the [NavigationBar] only shows the *visible* subset.
/// We maintain a [branchIndices] list that maps each visible destination
/// position → its branch index, then use it to translate between the two.
class HomeShell extends ConsumerWidget {
  const HomeShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);

    // Build the ordered list of tabs that should actually appear.
    final List<AppTab> visibleTabs = AppTab.values
        .where((t) => settings.visibleTabs.contains(t))
        .toList();

    // Map: destination position (0-based in nav bar) → branch index (0-based in router).
    // E.g. if Tasks is hidden: [0, 1, 3] means dest[2] → goBranch(3).
    final List<int> branchIndices = visibleTabs.map((t) => t.index).toList();

    // Find which destination slot matches the currently active branch.
    int currentDestIndex =
        branchIndices.indexOf(navigationShell.currentIndex);

    // If the active branch was just hidden, jump to the first visible one.
    if (currentDestIndex == -1 && branchIndices.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigationShell.goBranch(branchIndices.first);
      });
      currentDestIndex = 0;
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentDestIndex.clamp(0, visibleTabs.length - 1),
        onDestinationSelected: (int destIndex) {
          final int branchIndex = branchIndices[destIndex];
          navigationShell.goBranch(
            branchIndex,
            initialLocation: branchIndex == navigationShell.currentIndex,
          );
        },
        destinations: visibleTabs
            .map(
              (AppTab tab) => NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
