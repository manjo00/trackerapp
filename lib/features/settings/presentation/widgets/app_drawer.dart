import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/settings/settings_provider.dart';

/// Right-side slide-in drawer — always reachable via the shell app bar,
/// regardless of which tabs are currently visible.
///
/// Sections:
///   1. Profile header  (account placeholder for now)
///   2. Quick theme switcher
///   3. Navigation to full Settings screen
///   4. Placeholder items (Export, About — for future phases)
///   5. App version footer
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    final SettingsNotifier notifier = ref.read(settingsProvider.notifier);
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme tt = Theme.of(context).textTheme;

    return Drawer(
      // Right-side drawers have the same width as left-side ones.
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Profile header ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: cs.primaryContainer,
                    child: Icon(
                      Icons.person_rounded,
                      size: 28,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Account',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Sign in coming soon',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withAlpha(130),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable middle (prevents overflow on short screens) ──
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
            Divider(color: cs.outlineVariant),

            // ── Quick theme switcher ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'THEME',
                style: tt.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<ThemeMode>(
                style: SegmentedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                ),
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_rounded, size: 16),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_rounded, size: 16),
                    label: Text('Auto'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_rounded, size: 16),
                    label: Text('Dark'),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (Set<ThemeMode> s) =>
                    notifier.setThemeMode(s.first),
              ),
            ),

            const SizedBox(height: 8),
            Divider(color: cs.outlineVariant),

            // ── Features (only tabs NOT already in the bottom nav — a
            //    visible tab needs no second entry point; user feedback) ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Text(
                'FEATURES',
                style: tt.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            if (!settings.visibleTabs.contains(AppTab.home))
              _DrawerTile(
                icon: Icons.home_rounded,
                label: 'Home',
                subtitle: 'Urgent, today & captured at a glance',
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/home');
                },
              ),
            if (!settings.visibleTabs.contains(AppTab.today))
              _DrawerTile(
                icon: Icons.wb_sunny_rounded,
                label: 'Today',
                subtitle: 'Unified daily view',
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/today');
                },
              ),
            if (!settings.visibleTabs.contains(AppTab.habits))
              _DrawerTile(
                icon: Icons.task_alt_rounded,
                label: 'Habits',
                subtitle: 'Daily streaks & recurring goals',
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/habits');
                },
              ),
            if (!settings.visibleTabs.contains(AppTab.lists))
              _DrawerTile(
                icon: Icons.folder_copy_rounded,
                label: kListNounPlural,
                subtitle: 'Task lists & sections',
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/lists');
                },
              ),
            if (!settings.visibleTabs.contains(AppTab.trackers))
              _DrawerTile(
                icon: Icons.bar_chart_rounded,
                label: 'Trackers',
                subtitle: 'Checklists & session logs',
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/trackers');
                },
              ),
            if (!settings.visibleTabs.contains(AppTab.planner))
              _DrawerTile(
                icon: Icons.calendar_today_rounded,
                label: 'Planner',
                subtitle: 'Month calendar & day details',
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/planner');
                },
              ),
            if (!settings.visibleTabs.contains(AppTab.workout))
              _DrawerTile(
                icon: Icons.fitness_center_rounded,
                label: 'Workout',
                subtitle: 'Programs, sets & rest timer',
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/workout');
                },
              ),
            _DrawerTile(
              icon: Icons.sticky_note_2_rounded,
              label: 'Notes',
              subtitle: 'Notebooks for rounds & knowledge',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/notes');
              },
            ),
            _DrawerTile(
              icon: Icons.calendar_month_rounded,
              label: 'Work schedule',
              subtitle: 'Day / night shifts calendar',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/schedule');
              },
            ),

            Divider(color: cs.outlineVariant),

            // ── Settings & info ─────────────────────────────────────────
            _DrawerTile(
              icon: Icons.inventory_2_rounded,
              label: 'Archived',
              subtitle: 'Restore or delete hidden items',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/archived');
              },
            ),
            _DrawerTile(
              icon: Icons.settings_rounded,
              label: 'Settings',
              subtitle: 'Tabs, theme & more',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/settings');
              },
            ),

            const _DrawerTile(
              icon: Icons.upload_rounded,
              label: 'Export data',
              subtitle: 'Coming in Phase 2',
              enabled: false,
            ),

            const _DrawerTile(
              icon: Icons.cloud_sync_rounded,
              label: 'Cloud sync',
              subtitle: 'Coming in Phase 2',
              enabled: false,
            ),

            const _VersionTile(),
                ],
              ),
            ),

            // ── Footer ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) => Text(
                  'Uplan  ·  v${snapshot.data?.version ?? '…'}',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withAlpha(80),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared tile ───────────────────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color fgColor =
        enabled ? cs.onSurface : cs.onSurface.withAlpha(80);

    return ListTile(
      leading: Icon(icon, color: fgColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withAlpha(enabled ? 130 : 80),
              ),
            )
          : null,
      onTap: enabled ? onTap : null,
      dense: true,
    );
  }
}

/// About row showing the real installed version (package_info) instead of a
/// hardcoded string that drifts from pubspec.yaml.
///
/// Hidden extra: 7 quick taps toggles developer mode (Android build-number
/// style) — reveals dev-only tooling like the GitHub feedback sync that
/// shouldn't be visible in the build friends install.
class _VersionTile extends ConsumerStatefulWidget {
  const _VersionTile();

  @override
  ConsumerState<_VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends ConsumerState<_VersionTile> {
  int _taps = 0;
  DateTime _lastTap = DateTime.fromMillisecondsSinceEpoch(0);

  void _onTap() {
    final DateTime now = DateTime.now();
    // Slow taps reset the streak — this must never trigger by accident.
    _taps = now.difference(_lastTap).inSeconds < 2 ? _taps + 1 : 1;
    _lastTap = now;
    if (_taps < 7) return;
    _taps = 0;

    final bool enable = !ref.read(settingsProvider).devMode;
    ref.read(settingsProvider.notifier).setDevMode(enable);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(enable ? 'Developer mode enabled' : 'Developer mode disabled'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) => _DrawerTile(
          icon: Icons.info_outline_rounded,
          label: 'About',
          subtitle: 'Version ${snapshot.data?.version ?? '…'}',
          enabled: false,
        ),
      ),
    );
  }
}
