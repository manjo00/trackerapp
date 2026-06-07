import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../settings/app_settings.dart';
import '../settings/settings_provider.dart';
import '../../features/settings/presentation/widgets/app_drawer.dart';

/// The persistent shell that wraps every tab screen.
///
/// Upgraded to [ConsumerStatefulWidget] for two reasons:
///   1. Watches [settingsProvider] (tab visibility + theme).
///   2. Stores [_scaffoldKey] so the app bar's profile button can open
///      the [endDrawer] from within the same build context.
///
/// The shell provides:
///   • A persistent [AppBar] with a dynamic title (per active tab) and
///     a profile/menu icon that opens [AppDrawer] — always accessible
///     regardless of which tabs are currently visible.
///   • A [NavigationBar] filtered to only the tabs the user has enabled.
///   • A right-side [AppDrawer] (endDrawer) with quick settings, theme
///     toggle, and placeholders for future features.
///
/// Individual tab screens no longer need their own AppBar — this one
/// handles it for them, updating the title automatically on tab switch.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  // Key needed to call _scaffoldKey.currentState?.openEndDrawer()
  // from the app bar action button.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── Title helpers ───────────────────────────────────────────────────────

  Widget _buildTitle(int branchIndex) {
    if (branchIndex == AppTab.today.index) {
      // Today tab shows a two-line title with the current date.
      final DateTime now = DateTime.now();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today'),
          Text(
            _formattedDate(now),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withAlpha(140),
                ),
          ),
        ],
      );
    }
    // All other tabs use their simple label.
    return Text(_labelForBranch(branchIndex));
  }

  String _labelForBranch(int branchIndex) => switch (branchIndex) {
        0 => 'Today',
        1 => 'Inbox',
        2 => 'Habits',
        3 => 'Tasks',
        4 => 'Planner',
        5 => 'Trackers',
        6 => 'Workout',
        _ => 'Life Tracker',
      };

  static String _formattedDate(DateTime d) {
    const List<String> weekdays = [
      '', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    const List<String> months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${weekdays[d.weekday]}, ${months[d.month]} ${d.day}';
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = ref.watch(settingsProvider);

    final List<AppTab> visibleTabs = AppTab.values
        .where((t) => settings.visibleTabs.contains(t))
        .toList();

    final List<int> branchIndices = visibleTabs.map((t) => t.index).toList();

    int currentDestIndex =
        branchIndices.indexOf(widget.navigationShell.currentIndex);

    if (currentDestIndex == -1 && branchIndices.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.navigationShell.goBranch(branchIndices.first);
      });
      currentDestIndex = 0;
    }

    return Scaffold(
      key: _scaffoldKey,

      // ── Persistent app bar ────────────────────────────────────────────
      appBar: AppBar(
        title: _buildTitle(widget.navigationShell.currentIndex),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            tooltip: 'Menu',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          const SizedBox(width: 4),
        ],
      ),

      // ── Right-side slide-in panel ─────────────────────────────────────
      endDrawer: const AppDrawer(),

      // ── Tab content ───────────────────────────────────────────────────
      body: widget.navigationShell,

      // ── Bottom nav (filtered by settings) ────────────────────────────
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentDestIndex.clamp(0, visibleTabs.length - 1),
        onDestinationSelected: (int destIndex) {
          final int branchIndex = branchIndices[destIndex];
          widget.navigationShell.goBranch(
            branchIndex,
            initialLocation:
                branchIndex == widget.navigationShell.currentIndex,
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
