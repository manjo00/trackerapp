import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/settings/app_settings.dart';
import '../../../../../core/settings/settings_provider.dart';

/// App settings screen — reached via the ⚙ icon on the Today tab.
///
/// Two sections:
///   1. Appearance — Light / System / Dark segmented choice.
///   2. Navigation tabs — toggle which tabs appear in the bottom bar.
///      At least one tab must always be visible.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    final SettingsNotifier notifier = ref.read(settingsProvider.notifier);
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Appearance ─────────────────────────────────────────────────
          const _SectionHeader(label: 'Appearance'),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface.withAlpha(160),
                      ),
                ),
                const SizedBox(height: 10),
                // Material 3 SegmentedButton — three mutually exclusive options.
                SegmentedButton<ThemeMode>(
                  style: SegmentedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded, size: 18),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_rounded, size: 18),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded, size: 18),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (Set<ThemeMode> selection) {
                    notifier.setThemeMode(selection.first);
                  },
                ),
              ],
            ),
          ),

          const Divider(indent: 16, endIndent: 16),

          // ── Navigation tabs ────────────────────────────────────────────
          const _SectionHeader(label: 'Navigation tabs'),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Choose which tabs appear in the bottom bar. '
              'At least one must stay on.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withAlpha(140),
                    height: 1.5,
                  ),
            ),
          ),

          for (final AppTab tab in AppTab.values)
            _TabToggleTile(
              tab: tab,
              isVisible: settings.visibleTabs.contains(tab),
              isLastVisible: settings.visibleTabs.length == 1 &&
                  settings.visibleTabs.contains(tab),
              onChanged: (bool value) =>
                  notifier.setTabVisible(tab, visible: value),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
      ),
    );
  }
}

// ── Tab toggle tile ───────────────────────────────────────────────────────────

class _TabToggleTile extends StatelessWidget {
  const _TabToggleTile({
    required this.tab,
    required this.isVisible,
    required this.isLastVisible,
    required this.onChanged,
  });

  final AppTab tab;
  final bool isVisible;

  /// True when this is the only remaining visible tab — toggling it off
  /// would leave the nav empty, so we disable the switch.
  final bool isLastVisible;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return SwitchListTile(
      secondary: Icon(
        isVisible ? tab.selectedIcon : tab.icon,
        color: isVisible ? cs.primary : cs.onSurface.withAlpha(100),
      ),
      title: Text(tab.label),
      subtitle: isLastVisible
          ? Text(
              'Cannot hide the last tab',
              style: TextStyle(
                fontSize: 12,
                color: cs.error.withAlpha(180),
              ),
            )
          : null,
      value: isVisible,
      // Disable the switch when this is the only visible tab.
      onChanged: isLastVisible ? null : onChanged,
    );
  }
}
