import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../core/backup/backup_service.dart';
import '../../../../../core/database/database_provider.dart';
import '../../../../../core/settings/app_settings.dart';
import '../../../../../core/settings/settings_provider.dart';
import '../../../../../core/update/update_service.dart';
import 'diagnostics_screen.dart';
import 'live_notification_settings_screen.dart';
import 'widget_settings_screen.dart';

/// App settings screen.
///
/// Sections:
///   1. Appearance — Light / System / Dark theme.
///   2. Notifications — daily reminder toggle + time picker.
///   3. Navigation tabs — toggle which tabs appear in the bottom bar.
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

          // ── Notifications ──────────────────────────────────────────────
          const _SectionHeader(label: 'Notifications'),

          SwitchListTile(
            secondary: Icon(
              Icons.notifications_rounded,
              color: settings.notificationsEnabled
                  ? cs.primary
                  : cs.onSurface.withAlpha(100),
            ),
            title: const Text('Daily reminder'),
            subtitle: const Text('A nudge to check your habits and tasks'),
            value: settings.notificationsEnabled,
            onChanged: (bool value) =>
                notifier.setNotificationsEnabled(value),
          ),

          // Time picker row — only shown when notifications are enabled.
          if (settings.notificationsEnabled)
            _ReminderTimeTile(
              time: settings.reminderTime,
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: settings.reminderTime,
                );
                if (picked != null) {
                  notifier.setReminderTime(picked);
                }
              },
            ),

          // (Notification test tools + reminder fixes moved to the
          // Diagnostics screen under "Testing & support".)
          const Divider(indent: 16, endIndent: 16),

          // ── Data / backup ──────────────────────────────────────────────
          const _SectionHeader(label: 'Data'),

          ListTile(
            leading: Icon(Icons.upload_file_rounded, color: cs.primary),
            title: const Text('Export data'),
            subtitle: const Text(
                'Save a backup file (share to Drive, email, etc.)'),
            onTap: () => _exportData(context, ref),
          ),
          ListTile(
            leading: Icon(Icons.download_rounded, color: cs.primary),
            title: const Text('Import data'),
            subtitle: const Text('Restore from a backup file — replaces all data'),
            onTap: () => _importData(context, ref),
          ),

          const Divider(indent: 16, endIndent: 16),

          // ── Home-screen widget ─────────────────────────────────────────
          const _SectionHeader(label: 'Home-screen widget'),

          ListTile(
            leading: Icon(Icons.widgets_rounded, color: cs.primary),
            title: const Text('Widget appearance'),
            subtitle:
                const Text('Background colour and transparency'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const WidgetSettingsScreen(),
              ),
            ),
          ),

          const Divider(indent: 16, endIndent: 16),

          // ── Live notification ──────────────────────────────────────────
          const _SectionHeader(label: 'Live notification'),

          ListTile(
            leading: Icon(Icons.notifications_paused_rounded,
                color: cs.primary),
            title: const Text('Live notification'),
            subtitle: const Text(
                'Persistent dashboard in the notification shade'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LiveNotificationSettingsScreen(),
              ),
            ),
          ),

          const Divider(indent: 16, endIndent: 16),

          // ── Testing & support ──────────────────────────────────────────
          const _SectionHeader(label: 'Testing & support'),

          ListTile(
            leading: Icon(Icons.health_and_safety_rounded, color: cs.primary),
            title: const Text('Diagnostics'),
            subtitle: const Text(
                'Check permissions, fix reminders, test notifications'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DiagnosticsScreen(),
              ),
            ),
          ),

          ListTile(
            leading: Icon(Icons.system_update_rounded, color: cs.primary),
            title: const Text('Check for updates'),
            subtitle: const Text('Fetch the latest version from GitHub'),
            onTap: () => _checkForUpdates(context),
          ),

          const Divider(indent: 16, endIndent: 16),

          // ── Labs / experimental ────────────────────────────────────────
          const _SectionHeader(label: 'Labs (experimental)'),

          SwitchListTile(
            secondary: Icon(Icons.science_rounded, color: cs.primary),
            title: const Text('Weekly muscle targets'),
            subtitle: const Text(
                'Adds a Targets mode to Workout: a per-muscle weekly '
                'scoreboard instead of fixed programs'),
            value: settings.experimentalTargets,
            onChanged: (v) =>
                notifier.setExperimentalTargets(v),
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

  // ── Reminder fix ──────────────────────────────────────────────────────────

  /// Requests the exact-alarm permission, then re-schedules every reminder so
  /// existing ones switch from inexact to exact alarms.
  // ── Backup handlers ───────────────────────────────────────────────────────

  /// Manual update check — immediate feedback either way (the launch-time
  /// auto-check is silent unless something is found).
  Future<void> _checkForUpdates(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Checking…'), duration: Duration(seconds: 1)),
    );
    final UpdateInfo? update = await UpdateService.check();
    if (!context.mounted) return;

    if (update == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('You\'re on the latest version ✅'),
      ));
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update available — v${update.version}'),
        content: const Text(
            'Downloads in your browser — open the file when done and '
            'Android will offer to install it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              UpdateService.download(update);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  /// Serialises the database to JSON, writes a temp file, and opens the share
  /// sheet so the user can save it anywhere (Google Drive, email, etc.).
  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final String json =
          await BackupService(ref.read(appDatabaseProvider)).exportToJson();
      final Directory dir = await getTemporaryDirectory();
      final String stamp = DateTime.now()
          .toIso8601String()
          .split('.')
          .first
          .replaceAll(':', '-');
      final File file =
          File('${dir.path}/life_tracker_backup_$stamp.json');
      await file.writeAsString(json);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Life Tracker backup',
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  /// Confirms, lets the user pick a backup file, then replaces all data.
  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    // Capture before any await so we don't use context across an async gap.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Import backup?'),
        content: const Text(
          'This replaces ALL current habits, tasks, trackers, workouts and '
          'shifts with the contents of the backup file. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Replace data'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    const XTypeGroup typeGroup = XTypeGroup(
      label: 'Backup (JSON)',
      extensions: ['json'],
    );
    final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;

    try {
      final String content = await file.readAsString();
      await BackupService(ref.read(appDatabaseProvider))
          .importFromJson(content);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              'Backup restored. Restart the app if anything looks off.'),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }
}

// ── Reminder time tile ────────────────────────────────────────────────────────

class _ReminderTimeTile extends StatelessWidget {
  const _ReminderTimeTile({required this.time, required this.onTap});

  final TimeOfDay time;
  final VoidCallback onTap;

  String _formatTime(TimeOfDay t) {
    final int hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final String minute = t.minute.toString().padLeft(2, '0');
    final String period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.access_time_rounded),
      title: const Text('Reminder time'),
      trailing: Text(
        _formatTime(time),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
      onTap: onTap,
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
      onChanged: isLastVisible ? null : onChanged,
    );
  }
}
